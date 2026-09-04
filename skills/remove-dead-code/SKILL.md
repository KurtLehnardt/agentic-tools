---
name: remove-dead-code
description: "Find what code is actually dead — and prove it. Runs two independent passes (static tools + reachability from real entry points), then an adversarial zero-trust critic that tries to refute every finding in both directions before anything is called dead. Separates truly-dead (delete) from dead-in-production-but-intentional (keep) from built-but-never-wired (a decision, not a delete). Trigger: find dead code, unused code, dead-code audit, what can I delete, is this code used, how much of this repo is dead, prune the codebase, unreferenced code, orphaned modules."
user-invocable: true
---

# /remove-dead-code — Find what's actually dead

You are an **orchestrator**. Your job is to find what is genuinely dead, **prove it**, and hand back a decision — not to trust a tool's word or start deleting.

> **"Dead" is a reachability question, not a grep question.** A symbol is dead if nothing *reachable from a real entry point* uses it. Static tools answer a different, weaker question — "does this name appear anywhere?" — so they lie in **both** directions: they call live framework handlers dead, and they call test-only-reachable code alive. Every finding is guilty until proven dead.

Run the adversarial pass (Phase 3) on the **strong model** (opus-tier via `/route`). A cheap critic rubber-stamps the first pass and defeats the point.

## Phase 1: SCOPE — draw the boundary, find the roots

Decide what is even a candidate, then find what "reachable" means.

```bash
# Real source only. Exclude vendored/generated/cache noise — it dwarfs the real code
#   and poisons every count.
#   e.g. venv/, node_modules/, .git/, dist/, build/, *.pyc, generated clients, migrations
find <src> -name '*.<ext>' | grep -vE '<vendored|generated|cache dirs>'
```

Then find the **true entry points** — the only roots reachability counts from. Read them, don't guess:
`Dockerfile`/`compose` `CMD`/`ENTRYPOINT`, `__main__`/`main`/`cli`, `package.json` scripts / `console_scripts`, serverless handlers, cron/queue workers, `README` run commands, web route roots. **Tests are not entry points.** Code reachable *only* from tests is dead-in-production even if grep finds callers.

## Phase 2: TWO INDEPENDENT PASSES — each catches what the other can't

Run both. They disagree on purpose; the disagreement is the signal.

**Pass A — static tools** (fast, local, over-reports):
```bash
# Python:  vulture <src> --min-confidence 80  (then 60);  ruff check <src> --select F401,F811,F841
# JS/TS:   knip  /  ts-prune  /  eslint no-unused-vars
# Go:      deadcode ./...  /  staticcheck
```
Reconcile the tools against each other — they have different blind spots. (Example seen in the wild: `ruff`'s scoped analysis flags unused imports that `vulture` misses because vulture counts a name as "used" if the text appears *anywhere* in the file; conversely vulture flags unused function params / loop-unpack vars that `ruff F841` ignores.) Where they conflict, the scoped tool wins for imports; hand-verify the rest.

**Pass B — reference-graph reachability** (slow, semantic, finds what tools can't):
For each module / exported symbol, ask: is it reachable from an entry point through non-test references? Flag:
- modules never imported outside tests or by other dead code,
- symbols referenced *only* in `tests/`,
- symbols referenced *only* by other already-dead symbols (transitively dead).

Pass A finds dead *lines*; Pass B finds dead *features*. The big wins (a whole subsystem nobody wired in) are only visible to B.

## Phase 3: ADVERSARIAL VERIFICATION — refute every finding, both directions

Spawn a **zero-trust critic** (strong model). It re-derives every verdict firsthand with grep/read and tries to **break** the first pass — this is where false positives die and misses surface. Same spirit as `/verdict`: trust nothing, regenerate the evidence.

For each **"dead"** claim, hunt for a hidden caller before accepting it. Default to LIVE if any of these reaches it:

| Pattern | Why the tool missed it |
|---|---|
| `@app.route` / `@socketio.on` / `@app.before_request` / Click / Celery / Django signals / pytest fixtures | framework dispatch — invoked by name/URL/event, no static call site |
| `getattr` / `importlib` / string registries / decorator dispatch tables | dynamic dispatch |
| dataclass fields, config schema, `sqlite row_factory`, `@property` read as a dict key | attribute access the call-graph doesn't model |
| `Protocol` / ABC / `@runtime_checkable` methods, NoOp / null-object shims mirroring an external API (e.g. an OTel stub) | interface stubs — signatures must exist even with no direct caller |
| serialization (`to_dict`/`from_dict`), `__all__`, plugin/entry-point hooks | referenced out-of-band |

For each **"live"** claim, invert it: is it referenced *only* by tests, or *only* by other dead code? Then it's dead-in-production regardless of the grep count. The critic must also **sweep for misses** — orphaned private helpers, initialized-but-never-consumed objects (a client/tracer built and never called), env vars wired to fields nothing reads, whole modules imported only by their own tests.

Emit a verdict per contested item: `CONFIRMED-DEAD` / `REFUTED-LIVE` / `UNCERTAIN`, each with the file:line evidence the critic regenerated itself.

## Phase 4: CLASSIFY — three buckets, three fates

Do **not** collapse "unused" into "delete." Sort every confirmed finding:

1. **Truly dead** → *delete.* Unreferenced anywhere (prod or test): unused imports, orphaned locals, never-called private helpers, no-op env wiring.
2. **Dead-in-production but intentional** → *keep.* Public API, `Protocol`/interface members, extension points, symmetric facade methods, test-only helpers. Reachable only from tests — by design. Deleting these breaks the contract, not the dead weight.
3. **Built but never wired** → *decide.* A complete, often tested feature that no entry point reaches — someone built it and never connected the last seam. This is **not** an auto-delete: it's a product call — **finish it** (wire the seam) or **cut it**. Surface it to the human with the LOC and the missing connection; never silently delete a feature.

## Phase 5: REPORT — numbers with honest denominators

Give two percentages, never one. "% dead" is meaningless without saying *which* dead.

```
|||DEAD-CODE|||
{
  "source_loc": 7873,
  "truly_dead":       { "loc": 45,  "pct": 0.6,  "fate": "delete",  "items": [ ... ] },
  "dead_in_prod":     { "loc": 1000, "pct": 13,  "fate": "keep|decide",
                        "note": "dominated by <feature> — built, tested, unwired" },
  "false_positives_filtered": 31,
  "overturned_by_critic": [ "<first-pass claim the critic reversed>" ],
  "missed_by_first_pass": [ "<dead code only the critic found>" ],
  "decisions_for_human": [ "<built-but-unwired feature>: finish or delete?" ]
}
|||DEAD-CODE|||
```

State the confidence caveat plainly: static-tool headline numbers overstate dead code (framework dispatch, dynamic access, interface stubs), and reachability's "dead-in-prod" figure is an **upper bound** — most of it is intentional surface, not removable. The only safe-to-delete number is bucket 1, post-critic.

## Bail-outs
- **No entry points found** → stop; you can't compute reachability. Ask the human what actually runs.
- **Critic and first pass disagree** → the critic's firsthand evidence wins; if still `UNCERTAIN`, keep it and flag it — never delete on doubt.
- **A "dead" symbol has test coverage** → it's bucket 2 or 3, not bucket 1. Tests are a contract; deleting the code means deleting the test, which is a decision, not cleanup.
