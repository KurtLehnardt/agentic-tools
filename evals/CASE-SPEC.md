# Eval case-authoring spec

Binding on every case added or edited under `evals/`. Verified against
`https://code.claude.com/docs/en/plugin-evals.md` and `claude plugin eval --help` on CLI
2.1.287, and against this tree as of the Wave 1 regrade (commit `d326358`). This document
replaces the earlier `CONVERSION-SPEC.md` draft, which taught two mistakes that each cost a
real, paid eval run. Both mistakes are named below so they are not relearned.

## Two formats exist. They are not the same format, and neither reads the other's files.

`evals/<skill>/<case-slug>/` (this directory) is the format `claude plugin eval` discovers,
wired via `experimental.evals: "evals"` in `.claude-plugin/plugin.json`.

`skills/<skill>/evals/evals.json` is a **separate, deliberately maintained format**, consumed
by the skill-creator plugin for interactive iteration inside a conversation. The official docs
say this directly: "the skill-creator plugin runs a similar comparison with its own
`evals/evals.json` format, and neither tool reads the other's case files." This repo keeps both
on purpose: 25 skill directories under `evals/`, and 25 matching `evals.json` files under
`skills/*/evals/`. `evals/lint.py` enforces that the case count in each `evals.json` equals the
number of `prompt.md` files for that skill. **Any change to a case's prompt or rubric must be
mirrored into the matching `evals.json` entry in the same edit** (same case order,
`expected_output` updated to match the new criteria.md). Editing only one format silently
desyncs the count and fails lint.

Do not write or imply that `evals.json` "is discovered by nothing" or is dead weight. It is
read by a different, real tool, for a different, real purpose.

## Target layout

For skill `<skill>`, each case in `skills/<skill>/evals/evals.json` has a matching directory:

```
evals/<skill>/<case-slug>/
├── prompt.md
└── graders/
    ├── criteria.md
    └── skill-fired.md
```

- `evals/` is the suite root at the REPO ROOT, wired via `experimental.evals` — not under `skills/`.
- `evals/<skill>/` is a grouping directory. Grouping dirs are not cases — they hold no `prompt.md`.
- `<case-slug>` is kebab-case, derived from what the case actually tests, e.g. `zero-user-habit-app`,
  `stub-passes-gate`, `concurrent-prod-deploy`. Not `case-1`. Must be unique within the skill.

## Every case runs in a fresh, empty, non-interactive sandbox. This is the normative starting fact, not an addendum.

Each run starts a brand-new session in `/private/tmp/e-XXXXX/home/cwd`: a directory with **no
commits, no files, no shell, no subagents**, and only the plugin under test loaded. The grader
sees only the final reply, the transcript, or a file Claude created during that run — nothing
else. There is no "your repo," "the branch," "package.json," or "our migrations" unless the
case supplies that state itself. Two real runs failed because rubrics assumed ambient project
state (`deploy`, 5 of 6 cases failed because the skill correctly refused a project that did not
exist) or assumed tool access the default grant does not provide (`gate`, two cases never fired
the skill because the grant could not support the skill's actual job). Both failures traced to
the rubric, not the skill. Writing a case without holding this fact in mind is how that happens
again.

**Supply state one of two ways, if the rubric needs any:**
1. Inline in the prompt body — paste the file content, diff, or config the rubric grades.
   Cheapest, and correct for small state. `evals/architect-review/mixed-severity-findings/prompt.md`
   is the model to copy: it pastes full inline project state rather than referring to a project
   that doesn't exist in the sandbox.
2. A `case.yaml` with a `context` block supplying read-only fixture directories or a
   `scaffold_script` (the latter only runs under `--scaffold`, and only ever on case files you
   authored — it executes as you).

**Grade what is observable in an empty sandbox with no shell.** If a rubric needs a file to
exist, either ship the fixture or grade the described plan instead. Never grade an effect that
cannot happen under the sandbox and the tool grant the case actually has.

## prompt.md

```markdown
---
name: <skill>-<case-slug>
description: <one line, what this case tests>
tags: [<skill>]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

<the `prompt` value from evals.json, verbatim>
```

Rules:
- `name` MUST be `<skill>-<case-slug>` so `--case '<skill>-*'` selects the whole skill. Globally unique.
- Unknown frontmatter keys are a hard error, not a warning. Use only the keys shown above.
- Do NOT set `runs` (default 3 is correct). Do NOT set `model`, `plugins`, `env`, `schema_version`.
- Prompt body is the `prompt` string verbatim. Preserve sloppy lowercase/typos exactly — register
  variation is deliberate test surface.
- Raise `max_turns` to 20 only for cases whose skill is a multi-phase orchestrator (build, ship, idea).

### Why `allowed_tools: [Read, Glob, Grep, Skill]` is the default, and why you must not treat it as universal

This grant is read-only by design: it grades **what the reply says**, not what the filesystem
ends up containing. A case under this grant cannot write a gate file, cannot run a stub, cannot
execute a build, cannot touch git. That is deliberate — it is cheap, deterministic, and it is
what makes "describe the correct action" a fair bar to grade against. It is also exactly what
broke the `gate` run: `gate`'s job is to write a gate file and run a stub against it, and under
`[Read, Glob, Grep, Skill]` it structurally cannot do either. The skill said so in its own reply.
The fix was not to the skill — it was to the rubric and the prompt, per the artifact-in-reply
rule below.

So: **keep the read-only grant as the default for every case**, and when the rubric needs to
grade a produced artifact (a gate file, a generated test suite, a policy JSON, a config), do not
loosen the grant to get there. Instead:

1. Append exactly one sentence to the END of the prompt body: `Include the complete <artifact>
   in your reply.` Do not change any other prompt wording, casing, or typos.
2. Grade the in-reply artifact's content with a `regex` grader over `last_message` or an `llm`
   grader, not a `file_exists` grader expecting a write that could not happen.

If a case genuinely requires execution (running a real build, deploying, invoking a shell), that
is an **exec-tier case**, and it needs its own run with `--allow-tools` broadened for that run —
see "Mixed read-only/exec suites" below. Do not widen the whole suite's default grant to
accommodate one case.

## graders/criteria.md (the LLM grader)

```markdown
---
type: llm
weight: 1
---

PASS if:
- <positive assertion>
- <positive assertion>

FAIL if:
- <negative assertion, from the rubric's "should NOT" / "must NOT" clauses>
- <any assertion whose violation should sink the case>
```

Rules:
- Convert the single `expected_output` prose blob into explicit PASS/FAIL bullet lists.
- **Every bullet must be checkable from the final message text alone.** Rewrite any bullet
  asserting an action occurred ("Runs npm test", "Executes migrations", "Deletes the branch",
  "Captures the URL") into a bullet asserting the reply states, names, or shows it: "Names
  `npm test` as a required pre-flight step and states deployment stops if it fails." `lint.py`
  flags bare exec verbs (`Runs`, `Executes`, `Deploys`, `Rolls back`, `Deletes`, `Removes`,
  `Applies`, `Installs`, `Commits`, `Pushes`, `Merges`) at the start of a PASS bullet for exactly
  this reason — fix the bullet, don't suppress the lint.
- **Execution-observation bullets** — a bullet that requires an observed execution, such as a
  stub failing a gate check — become: the reply must present the stub code AND identify, by
  name, the specific assertion that rejects it, with the reasoning shown. Never grade "the stub
  failed" as an event; grade "the reply shows the stub and names what rejects it."
- **Exact-quote demands are relaxed to "substantively conveys"** wherever the criterion names an
  unobservable judgment or asks for a human decision, EXCEPT literal sentinels the skill mandates
  as machine-readable output (e.g. `|||VERDICT|||`), which stay literal and exact.
- **Single-turn conflicts are not allowed.** If the skill's correct behavior for this prompt is
  to push back and stop, the rubric must not also demand a finished artifact in the same case.
  Pick one and say which in criteria.md: either (a) pushback plus a provisional artifact with
  clearly-marked placeholder thresholds, when the skill's actual job is producing an artifact
  even under uncertainty, or (b) pushback alone passes, when the skill's job is to refuse. Do not
  write a rubric that can only be satisfied by two incompatible replies.
- Every "should NOT" / "must NOT" / "NOT a ..." clause in the source rubric becomes a FAIL bullet.
  Do not drop one. Do not soften one.
- Keep each bullet independently checkable. Split compound sentences into separate bullets.
- Preserve exact technical payload from the rubric: numbers, thresholds, tolerance bands, file paths,
  phase names, command names, quoted output strings. Do not paraphrase these.
- Do not invent assertions the source rubric does not contain.
- `focus` defaults to `last_message`. Omit it unless the rubric grades created files, in which case
  use `focus: files` (a list of created paths) — note it does NOT give file contents. To grade an
  artifact's content, use the artifact-in-reply rule above, or `focus: { source: file, path: <path> }`
  only on a case whose grant and prompt actually produce that file on disk.

### The artifact-in-reply sentence (verbatim)

Where the rubric grades a produced artifact, append exactly this sentence to the end of the
prompt body, substituting the artifact name, and nowhere else in the document:

> Include the complete `<artifact>` in your reply.

Do not paraphrase it, move it, or add it mid-prompt. It is appended, once, at the end.

## graders/skill-fired.md (deterministic, free)

```markdown
---
type: tool_used
tool: Skill
input_match: '"skill"\s*:\s*"(?:[\w-]+:)?<skill>"'
arm: with-only
---
```

Rules:
- Substitute `<skill>` for the real skill name. The `(?:[\w-]+:)?` prefix matches the
  `plugin:skill` namespaced form too.
- `arm: with-only` is required: it makes this a plugin-fired indicator rather than part of the
  ablation score delta.
- Body is empty. Frontmatter only.
- Every case gets this file, with one exception: a case whose sandbox state makes the skill
  firing undecidable should instead carry a FAIL bullet in criteria.md describing what a
  non-firing reply looks like.

## Deterministic graders — prefer them over the judge

Where a rubric asserts something mechanically checkable, add a third grader file instead of
leaving it to the LLM judge. Costs nothing and cannot be talked around.

Assert a literal string is absent (e.g. sandbox must not emit a wildcard policy):
```markdown
---
type: regex
pattern: '"allowWrite"\s*:\s*\[\s*"/"'
match: not_contains
weight: 1
---
```

**`not_contains` patterns must not be trippable by a correct refusal that quotes the forbidden
string.** `"I will NOT run \`git branch -D\`"` is a correct refusal, and a naive `not_contains`
on `git branch -D` fails it. Either tighten the pattern to only match an affirmative,
execution-form statement, or delete the grader and rely on a FAIL bullet in criteria.md instead.
Keep `not_contains` only for patterns a correct answer can never contain under any phrasing —
fabricated API keys, a literal wildcard policy blob, secrets.

Assert a tool was never used (e.g. deploy must not execute during a refusal case):
```markdown
---
type: tool_used
tool: Bash
min: 0
max: 0
---
```

Use these for: forbidden literal output, forbidden tool calls, required ordering (`tool_order`).
Name such files for what they check: `no-wildcard-policy.md`, `no-bash-execution.md`.

## Never write an always-passing grader

This is the subtlest trap in the exercise, and it has already produced wrong scores in this
repo. A `tool_used` grader with `min: 0, max: 0` on a tool the case's `allowed_tools` never
grants is a weight-1 grader that **passes on every single run, unconditionally**, because the
tool could not have been called regardless of what the agent did or wanted to do. That is not a
test — it is a free 0.5 floor under every case's score. If the rest of the case scores 0 on a
genuine failure, this grader alone drags the reported score from 0.0 to 0.5, which reads as "half
right" when the true answer is "entirely wrong." Ten of these existed in this repo's suite and
were deleted in the Wave 1 regrade.

The check: does the case's `allowed_tools` (always `[Read, Glob, Grep, Skill]` under this spec's
default) already exclude the tool this grader guards? If yes, the grader is inert on every
default run and must not exist as its own file. Before deleting it, confirm the behavior it was
meant to guard against is captured as an explicit FAIL bullet in that case's criteria.md — add
the bullet if it's missing, so the behavior is still checked, just by the judge instead of a free
pass. `evals/lint.py` enforces this: it flags every `tool_used` grader with both `min: 0` and
`max: 0` as an error (`min_max_zero` check), specifically because of this history.

A `min: 0, max: 0` grader is legitimate only on an exec-tier run where the tool IS in that run's
`--allow-tools` grant — there, the assertion is live and catches a real violation. It is never
legitimate as a standing file in a suite whose default grant already excludes the tool.

## Mixed read-only/exec suites: one invocation per tool grant

`--allow-tools` is a **per-run flag, not a per-case setting**. There is no frontmatter key that
grants a wider tool set to one case while the rest of the suite stays read-only. A skill whose
cases span both tiers — most cases grading "did the reply describe the right action," one or two
grading "did it actually refuse to run a destructive command when granted the ability to" —
needs **two separate `claude plugin eval` invocations**, filtered by `--case` or `--tag`:

```sh
claude plugin eval . --case 'deploy-*' --tag read-only
claude plugin eval . --case 'deploy-*' --tag exec --allow-tools Bash
```

Document the exec tier as optional and budget-gated: it costs real money per run (see Cost
below) and should not be part of the default "run the whole suite" invocation. Tag exec-tier
cases explicitly (`tags: [deploy, exec]`) so they can be excluded from a cheap default run and
included only deliberately.

## Judge model: validate with sonnet, don't trust haiku's first verdict

`--judge-model` defaults to haiku. The docs warn explicitly: a small judge model can mark a
correct answer wrong purely because it's formatted differently from what the rubric describes.
If a case's `tool_used: Skill` grader passes but the LLM-graded score is low or `Δ` is negative,
suspect the judge before suspecting the skill or the rubric. Re-run that case with
`--judge-model sonnet` before concluding the case or the skill is actually broken, and tighten
the rubric wording if sonnet and haiku disagree, so formatting stop deciding the verdict.

## Cost: do not project from a cheap sample

Measured across real runs in this repo: **$0.21/run average**, ranging from $0.06 (a `deploy`
run) to $1.03 (one `gate` run). An earlier estimate of $0.061/run, taken from a small or
unrepresentative sample, was roughly 8x low — and that bad estimate caused a run to abort
mid-suite when it hit its `--max-cost-usd` ceiling early. Before setting a cost ceiling for a
new or expanded run, assume cost per case varies by over an order of magnitude depending on
prompt length, `max_turns`, and how many `llm`/`baseline` graders fire, and size the ceiling off
a measured sample from a run of comparable cases — not off the cheapest case you've seen.

## `evals/lint.py`

Run it before committing any change under `evals/`:

```sh
python3 evals/lint.py            # whole suite
python3 evals/lint.py evals/<skill>   # one skill
```

It checks, per case: the directory has a `prompt.md` and a non-empty `graders/`; `prompt.md`
frontmatter parses as YAML and uses only the allowed keys; `name` equals `<skill>-<case-slug>`
and is globally unique; `allowed_tools` equals `[Read, Glob, Grep, Skill]`; every grader's
`pattern`/`input_match` compiles as a regex; every `tool_used: Skill` grader carries
`arm: with-only` and an `input_match` naming the skill; no `tool_used` grader has both `min: 0`
and `max: 0`; no PASS bullet in `criteria.md` opens with a bare exec verb (`Runs`, `Executes`,
`Deploys`, `Rolls back`, `Deletes`, `Removes`, `Applies`, `Installs`, `Commits`, `Pushes`,
`Merges`), excluding named false positives like "Pushes back" and plural-noun uses ("Commits
follow convention"); and that each `skills/<skill>/evals/evals.json` case count matches the
number of `prompt.md` files for that skill in `evals/<skill>/`. It is static and free — it does
not call a model and does not run a case. A clean `lint.py` run does not mean a case will pass
`claude plugin eval` (it checks structure, not correctness), but a dirty one guarantees that case
cannot be trusted regardless of its score.

## Regex engine

Regex graders use JavaScript regex syntax (the docs confirm this directly in troubleshooting:
"regexes use JavaScript syntax"). Only the `i` flag is documented as supported via `flags: i`;
inline `(?i)` is explicitly unsupported, and there is no multiline flag documented, so `^`/`$`
cannot be relied on to match mid-message and `.*` cannot be relied on to cross a newline — write
patterns accordingly (anchor to whole-message boundaries, or don't anchor).

**Open question a validation run would settle:** several graders in this suite now rely on
negative lookbehind (`(?<!...)`) to exclude backtick-quoted mentions of a forbidden string from
tripping a `not_contains` grader. Negative lookbehind works in a JavaScript regex engine (ES2018+)
and the docs confirm the engine is JavaScript, so this should work — but it has not been executed
against a real run in this repo (no case here has ever been run; see `evals/README.md`'s "Has it
been run?" section). Treat any grader using lookbehind as unverified until a real run against
that case confirms the engine accepts the syntax, and prefer a simpler pattern (e.g. requiring an
execution-form match rather than lookbehind exclusion) wherever one gets the same result without
depending on it.

## Scope

- Touch only `evals/<skill>/**` for the skill you're editing. Nothing under `skills/` except the
  matching `evals.json`, which must be updated in the same edit (see "Two formats exist" above).
  No other skill's dirs.
- Do not edit `.claude-plugin/plugin.json`, README.md, or any `SKILL.md`.
- Do not run git commands as part of case authoring. Do not run `claude plugin eval` without
  confirming the cost ceiling and judge model first — see Cost and Judge model above.

## Self-check before returning a case or a batch of cases

- Case count in `evals/<skill>/` matches case count in `skills/<skill>/evals/evals.json`. No
  case dropped, none invented, in either direction.
- Every FAIL bullet traces to a real clause in the source rubric.
- Every case dir holds `prompt.md` AND `graders/` with at least one grader file.
- No grouping dir holds a `prompt.md`.
- No PASS/FAIL bullet asserts something unobservable from the final message, the transcript, or
  a file the case's own grant and prompt can actually produce.
- No case demands both pushback-and-stop and a finished artifact in the same reply.
- No `tool_used` grader has `min: 0, max: 0` on a tool the case's `allowed_tools` already
  excludes, without a backing FAIL bullet in criteria.md.
- No `not_contains` grader can be tripped by a correct refusal that quotes the forbidden string.
- YAML frontmatter parses: `---` delimited, no tabs, quote any value containing `:` or `#`.
- Regex `input_match` and `pattern` values are single-quoted so backslashes survive YAML, use
  only JavaScript regex syntax, and rely on only the `i` flag.
- `python3 evals/lint.py evals/<skill>` passes clean.
