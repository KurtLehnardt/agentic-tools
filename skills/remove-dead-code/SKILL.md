---
name: remove-dead-code
description: "Find what code is actually dead, prove it, and optionally remove it. Runs two independent passes (static tools + reachability from real entry points), then dispatches a SEPARATE zero-trust critic subagent that re-derives every finding from scratch and refutes it in both directions before anything is called dead. Two modes: audit (report only, the default) and audit-and-fix (delete the confirmed-dead, then verify the suite stays green). Separates truly-dead (delete) from dead-in-production-but-intentional (keep) from built-but-never-wired (a human decision). Trigger: find dead code, unused code, dead-code audit, what can I delete, is this code used, how much of this repo is dead, prune the codebase, unreferenced code, orphaned modules, remove dead code."
user-invocable: true
---

# /remove-dead-code — Find what's actually dead

You are an **orchestrator**. Find what is genuinely dead, **prove it with a separate critic**, and either report it or remove-and-verify it — never trust a tool's word, never delete on doubt.

> **"Dead" is a reachability question, not a grep question.** A symbol is dead if nothing *reachable from a real entry point* uses it. Static tools answer a weaker question — "does this name appear anywhere?" — so they lie in **both** directions: they call live framework handlers dead, and they call test-only-reachable code alive. Every finding is guilty until proven dead.

**Pick the mode first** (ask the caller or infer from the request):
- **audit** *(default)* — analyze and report. Delete nothing.
- **audit-and-fix** — do the audit, then delete bucket 1 (truly dead) and verify the suite stays green (Phase 6). Requires an explicit go; never fix in audit mode.

## Phase 1: SCOPE — boundary, roots, library-check, tools

**Candidate set.** Real source only — exclude vendored/generated/cache noise (`venv/`, `node_modules/`, `dist/`, `build/`, `*.pyc`, generated clients, migrations); it dwarfs the real code and poisons every count.

**Find the true entry points** — the only roots reachability counts from. Read them, don't guess: `Dockerfile`/`compose` `CMD`/`ENTRYPOINT`, `__main__`/`main`/`cli`, `package.json` scripts / `console_scripts`, serverless handlers, cron/queue workers, web route roots, `README` run commands. **Tests are not entry points.**

**Library-vs-app branch (critical — skipping it flags your whole public API as dead).** Is this a *library/package*, not an app? — a `pyproject.toml`/`package.json`/`go.mod` that publishes symbols, or a package imported by siblings in a monorepo. If so, **every public export is an entry-point root** (`__all__`, `export`, exported Go identifiers, `console_scripts`) — external callers you can't see reach them. "Unused within this repo" is NOT dead for a library; only truly-private symbols are candidates.

**Tool bootstrap.** Confirm each tool actually exists (`which vulture`, `npx knip --version`, in-venv path) before relying on it. A missing tool silently no-ops a pass and collapses the two passes into one — if you can't install it, record that the pass was skipped; never proceed as if it ran.

## Phase 2: TWO INDEPENDENT PASSES — each catches what the other can't

Run both. They disagree on purpose; the disagreement is the signal. **Carry the UNION of both passes into Phase 3** — a symbol flagged by either is a candidate; never drop Pass B's feature-level hits because Pass A was easier.

**Pass A — static tools** (fast, local, over-reports dead *lines*):
```bash
# Python:  vulture <src> --min-confidence 80 (then 60);  ruff check <src> --select F401,F811,F841
# JS/TS:   knip   (config-aware; the strongest)   /  ts-prune  /  eslint no-unused-vars
# Go:      staticcheck  /  golangci-lint  (unused-symbol linters)
```
Reconcile the tools against each other — different blind spots, neither subsumes the other. `ruff`'s scoped import analysis and `vulture`'s **AST module-scope** reference check (vulture is AST-based — it does *not* count names in strings/comments, and it *does* flag unused imports) disagree only at the margins (a name re-referenced elsewhere); `vulture` also flags unused function params / loop-unpack vars that `ruff F841` ignores. Where they conflict, hand-verify.

**Pass B — reachability** (slower, semantic, finds dead *features* — invisible to Pass A):
Build the reference graph, don't eyeball it:
```bash
# Python: per-module importer check  grep -rn 'import <mod>\|from <mod>'  (or pydeps / importlab for the graph)
# JS/TS:  madge / knip for the import graph
# Go:     deadcode ./...   # whole-program reachability FROM main; this is a Pass-B tool and it UNDER-reports (opposite of vulture)
```
Walk imports transitively from each entry point; mark reachable. Flag: modules never imported outside tests or by other dead code; symbols referenced *only* in tests; symbols referenced *only* by already-dead symbols (transitively dead). Pass A finds dead lines; Pass B finds the whole subsystem nobody wired in.

## Phase 3: ADVERSARIAL VERIFICATION — a SEPARATE critic, refuting both directions

**Dispatch a fresh subagent** (Task/agent tool) on the strong model (`/route` to opus-tier) whose only inputs are the candidate list + repo path — **NOT your reasoning or first-pass conclusions.** It regenerates every piece of evidence from scratch. Same spirit as `/verdict`: trust nothing.

> **If you cannot spawn a separate context, say so and downgrade every verdict to UNCERTAIN.** Putting on a "critic hat" and grading your own first pass is not zero-trust — it confirms your priors and silently reduces this skill to a dressed-up `vulture` run. The separation is the load-bearing part.

For each **"dead"** claim, hunt for a hidden caller before accepting it — default LIVE if any of these reaches it:

| Pattern | Why the tool missed it |
|---|---|
| `@app.route` / `@socketio.on` / `@app.before_request` / Click / Celery / Django signals / pytest fixtures / DI containers | framework dispatch — invoked by name/URL/event, no static call site |
| `getattr` / `importlib` / dynamic `import()` / string registries / decorator dispatch tables / reflection | dynamic dispatch |
| dataclass fields, config schema, `sqlite row_factory`, `@property` read as a dict key, Go interface satisfaction | attribute/structural use the call-graph doesn't model |
| `Protocol` / ABC / `@runtime_checkable` methods, NoOp / null-object shims mirroring an external API (e.g. an OTel stub) | interface stubs — signatures must exist with no direct caller |
| serialization (`to_dict`/`from_dict`), `__all__` / barrel `index.ts` re-exports, plugin/entry-point hooks, file-based routing (Next.js), `//go:embed`, build tags, `init()` | referenced out-of-band or by the toolchain |
| guarded by a feature flag / config / env / lazy or conditional import | dead in the profile you see, live under another — check ALL config profiles, default LIVE |

A framework pattern (`@app.route` present) is *evidence* of life, not proof — confirm the handler is actually registered on a live app object reachable from an entry point, not merely that the decorator text exists. For each **"live"** claim, invert it: referenced *only* by tests, or *only* by other dead code → dead-in-production regardless of grep count. The critic must also **sweep for misses** — orphaned private helpers, initialized-but-never-consumed objects (a client/tracer built and never called), env vars wired to fields nothing reads, modules imported only by their own tests.

Emit a verdict per contested item: `CONFIRMED-DEAD` / `REFUTED-LIVE` / `UNCERTAIN`, each with the file:line evidence the critic regenerated itself.

## Phase 4: CLASSIFY — three buckets, three fates

Do **not** collapse "unused" into "delete." Sort every CONFIRMED finding:

1. **Truly dead** → *delete* (audit-and-fix only). Unreferenced anywhere (prod or test): unused imports, orphaned locals, never-called private helpers, no-op env wiring.
2. **Dead-in-production but intentional** → *keep.* Public API, `Protocol`/interface members, extension points, symmetric facade methods, test-only helpers. Reachable only from tests, by design.
3. **Built but never wired** → *decide (human).* A complete, self-contained feature whose only missing piece is the call that connects it to an entry point. **Not** an auto-delete — surface it with the LOC + the missing connection so a human chooses finish-or-cut.

**Keep vs decide rule:** is a production path *supposed* to reach it? An interface member / documented extension point / symmetric facade → intentional (bucket 2). A whole feature that just needs its connecting call → unwired (bucket 3). When intent is unclear, it's bucket 3 — surface it, don't guess.

## Phase 5: REPORT — honest numbers, three buckets

Never give one "% dead." Emit the three buckets separately:
```
|||DEAD-CODE|||
{
  "mode": "audit" | "audit-and-fix",
  "source_loc": 7873,
  "truly_dead":       { "loc": 45,  "pct": 0.6, "fate": "delete", "items": [ ... ] },
  "intentional_keep": { "loc": 300, "pct": 3.8, "fate": "keep",   "note": "Protocol/API/extension surface, test-covered" },
  "decisions":        { "loc": 728, "pct": 9.2, "fate": "decide", "items": [ "<feature>: built+tested, unwired — finish or cut?" ] },
  "false_positives_filtered": 31,
  "overturned_by_critic": [ "<first-pass claim the critic reversed>" ],
  "missed_by_first_pass": [ "<dead code only the critic found>" ]
}
|||DEAD-CODE|||
```
State the caveat plainly: static-tool headline numbers overstate dead code (framework dispatch, dynamic access, interface stubs); the only safe-to-delete number is `truly_dead`, post-critic.

## Phase 6: FIX + VERIFY — audit-and-fix mode only

Run ONLY in audit-and-fix mode, ONLY on `truly_dead` (critic-CONFIRMED):
1. **Baseline green** — run the full suite + build/import smoke; record it passing.
2. **Delete** the bucket-1 items.
3. **Re-verify** — rerun the suite + build. If anything fails, or import/coverage shifts unexpectedly, **REVERT that item and reclassify** — a break means it wasn't dead.
4. **Never report a deletion you didn't watch go green.**
- Bucket 2 → leave untouched.
- Bucket 3 → present the finish-or-cut decision to the human; never auto-delete a feature, never auto-wire one.

## Bail-outs
- **No entry points found** → stop; you can't compute reachability. Ask what actually runs. (Remember: a *library* has roots — its public exports — even with no `main`.)
- **Can't spawn a separate critic** → verdicts are UNCERTAIN; do not delete anything.
- **Critic and first pass disagree** → the critic's firsthand evidence wins; if still UNCERTAIN, keep and flag — never delete on doubt.
- **A "dead" symbol has test coverage** → bucket 2 or 3, not 1. Deleting it means deleting its test — a decision, not cleanup.
