# Eval suite

Plugin eval cases for every skill in this plugin, in the format `claude plugin eval`
discovers. Wired via `experimental.evals` in `.claude-plugin/plugin.json`.

```
evals/<skill>/<case-slug>/
├── prompt.md          # frontmatter + the user turn under test
└── graders/
    ├── criteria.md    # llm grader: PASS if / FAIL if
    ├── skill-fired.md # tool_used: Skill, arm: with-only
    └── ...            # regex / tool_used graders for mechanical assertions
```

125 cases across 25 skills, backed by 277 grader files. Case names are `<skill>-<slug>`, so
one skill's suite runs with `--case '<skill>-*'`. Reproduce these numbers yourself rather than
trusting this file:

```sh
find evals -mindepth 2 -maxdepth 2 -type d ! -path "evals/results/*" | wc -l   # 125 cases
find evals -path "evals/results" -prune -o -path "*/graders/*" -type f -print | wc -l  # 277 graders
find evals -mindepth 1 -maxdepth 1 -type d ! -name results | wc -l             # 25 skills
```

## Running it

```sh
claude plugin eval .                      # whole suite, 3 runs per case per arm
claude plugin eval . --case 'deploy-*'    # one skill
claude plugin eval . --tag deploy         # same, by tag
claude plugin eval . --runs 1 --max-cost-usd 5
```

Budget before you run the whole thing: 125 cases x 3 runs x 2 ablation arms is ~750 agent runs.
`--runs 1` and `--case` keep that honest while iterating.

Results land in `evals/results/<timestamp>/` and are gitignored — each run leaves its own
`aggregate-result.json` and HTML report there, nothing is committed.

## Has it been run? Yes — twice, and both runs found a real defect in the rubrics.

**Run 1, `deploy` slice.** 6 cases, 3 runs each, $0.74 total. 1 of 6 passed; mean score delta
−0.08. Root cause: every case starts in an empty sandbox directory with exactly
`[Read, Glob, Grep, Skill]` — no shell, no files, no real project — but the `deploy` prompts and
rubrics assumed an existing project to deploy. The rubrics were grading actions the sandbox
cannot perform.

**Run 2, 18 cases budgeted.** Aborted at a $3 cost ceiling after completing 4, for $3.33 spent.
`gate` scored 0.25 mean, and two cases never fired the skill at all. Root cause: the rubrics
graded file writes and command execution (gate files, applied migrations, deleted branches) that
the suite's own read-only `allowed_tools` grant makes impossible to perform. Same defect family
as run 1: rubric wrote for a capability the case's own tool grant forbids.

**The subtlest trap: ten negative tool graders that always passed and inflated every score.**
Cases in `build`, `deploy`, `teardown`, `test`, and `remove-dead-code` carried `tool_used`
graders asserting Bash or Edit was never called (`min: 0, max: 0`). Because those tools were
never in any case's `allowed_tools` to begin with, the assertion was unconditionally true on
every run, regardless of what the agent actually did. The original version of this document
described that as graders that "carry no signal" — which was wrong in the dangerous direction.
Each one was a real weight-1 grader that always scored 1.0, so instead of being neutral it
*actively inflated the score*: a case where every other criterion failed landed at 0.5 instead
of 0.0, because the always-passing grader's 1.0 got averaged in. This is why `gate`'s 0.25 mean
in run 2 is a floor, not the true severity — some of the scores it's averaged against were
themselves propped up by this defect before the regrade. All ten have been deleted; the
behavior they guarded is now (per case) an explicit FAIL bullet in `criteria.md`, checked by the
judge instead of by an unconditionally-true mechanical grader.

## The response-grading doctrine

Every case grants only `[Read, Glob, Grep, Skill]` — no Bash, Write, or Edit — and that is
deliberate, not an oversight. The sandbox a case runs in is empty and ephemeral: no real
project, no shell, nothing the agent could have written survives or is inspectable. So a
grader that checks for a created file or an executed command can never pass honestly in this
tier; it would only measure whether the agent hallucinated success. Grading therefore targets
the agent's final reply, not the filesystem: a case is satisfied by a response that correctly
*states* the action it would take, not by the action having happened.

Where a case's rubric needs to grade the content of a would-be artifact (a gate file, a test
suite, a policy JSON, a generated config), the prompt appends exactly one sentence to the end
of its body: `Include the complete <artifact> in your reply.` That one line is what makes the
artifact's content inspectable by a reply-only grader — the agent writes the artifact inline in
its answer instead of to disk, and the criteria then grade that in-reply text. Nothing else
about the prompt changes when this sentence is added; wording, casing, and any existing typos
in the rest of the prompt are left alone deliberately, since register variation is itself part
of what the suite tests.

## The deferred execution tier

A second, optional invocation exists for cases that must prove real execution rather than a
correct description of it:

```sh
claude plugin eval . --allow-tools Bash Write Edit
```

Two things about this grant matter and are easy to get wrong:

- **The grant is per run, not per case.** `--allow-tools` widens the tool set for every case in
  that invocation. There is no way to run some cases read-only and others with exec tools in a
  single `claude plugin eval` call — a mixed-trust suite requires two separate invocations, one
  per tier, filtered with `--case` or `--tag`.
- **Bash under a grant needs an OS sandbox backend.** This is fine on macOS (the default
  backend works out of the box); confirm an equivalent exists before granting Bash on other
  platforms.

This plugin's suite does not currently ship a second, exec-tier set of cases — the `evals/`
tree above is entirely the read-only tier. Treat `--allow-tools` as available but unused until
someone deliberately builds out exec-tier cases.

## Judge model

The LLM grader defaults to **haiku**. The official `claude plugin eval --help` text warns that
a small judge model can mark a correct answer wrong purely because of its formatting rather than
its substance. Both real-run anomalies above (deploy's 1/6, gate's 0.25 mean with two misfires)
are consistent with that failure mode layering on top of the sandbox-reality defect — some
scored failures may be judge noise, not rubric defects, and the two are hard to tell apart on
haiku. For any run whose result will inform a rubric or skill change, pass:

```sh
claude plugin eval . --judge-model sonnet
```

## Cost

Measured, not guessed, over the ~19 runs actually paid for so far: **$0.21/run average**, with
wide spread by skill — `deploy` ran about $0.06/run, `gate` ran about $0.48/run, and one single
run hit $1.03. Do not treat the average as representative of any one skill.

Projected from that measured spread:

- Full suite at `--runs 1` (one run per case per arm, no repeat runs): roughly **$52**.
- Full suite at the default (3 runs per case, both ablation arms): roughly **$160**.

An earlier estimate of $0.061/run in this document was extrapolated from the single cheapest
case sampled and turned out to be wrong by about 8x once a denser sample (`gate`, the
expensive end) was measured. The lesson: extrapolate cost from a dense, representative sample,
never from the cheapest case you happen to have run.

## What the graders actually check

**Default focus is the final message.** No grader here inspects created files — there are no
`file_exists` graders and none use `focus: files`, for the reasons laid out in the doctrine
section above.

**Skill-fired graders are indicators, not score.** `arm: with-only` keeps them out of the
with/without ablation delta. They answer "did the skill actually trigger" rather than "was the
answer good", which otherwise confounds a plugin win with a model that would have answered
well anyway.

## `evals/lint.py`

Static lint over the eval case tree — no network, no `claude plugin eval` invocation, no cost.
Run it with:

```sh
python3 evals/lint.py            # whole tree
python3 evals/lint.py evals/deploy   # one skill only
python3 evals/lint.py --quiet    # counts only, no per-error lines
```

It checks, per case: `prompt.md` and a non-empty `graders/` directory exist; `prompt.md`'s
frontmatter parses, has a `name` matching `<skill>-<case>` and globally unique, has no keys
outside `{name, description, tags, allowed_tools, max_turns}`, and `allowed_tools` is exactly
`[Read, Glob, Grep, Skill]`; every grader's frontmatter parses and any `pattern`/`input_match`
regex compiles; every `tool_used: Skill` grader has `arm: with-only` and an `input_match`
containing the skill name; no `tool_used` grader has both `min: 0` and `max: 0` (the
always-passing defect described above — this is now a hard lint error, not just a one-time
regrade); and `criteria.md` PASS-section bullets don't use an action verb (`Runs`, `Executes`,
`Deploys`, `Rolls back`, `Deletes`, `Removes`, `Applies`, `Installs`, `Commits`, `Pushes`,
`Merges`) that asserts an occurred action rather than a stated one. Separately, it cross-checks
that each `skills/<skill>/evals/evals.json` case count matches the corresponding
`evals/<skill>/` prompt count.

Running it against its own fixtures surfaced two defects in the lint tool itself, both worth
knowing about before trusting its output blindly:

1. The `evals.json`-count cross-check silently treated `skills/sandbox` as a non-skill
   directory and skipped it, so that skill's case-count parity was never actually verified by
   the automated check (it currently matches — 6 and 6 — but only because someone checked by
   hand).
2. The action-verb rule's naive regex flagged `Pushes back` (a phrasal verb unrelated to `git
   push`) and the plural noun usage in `Commits follow conventional format` as if they were
   execution claims. Both are now excluded by an explicit false-positive pattern, but any new
   PASS bullet using one of the guarded words as a different part of speech should be checked
   against that exclusion list rather than assumed safe.

## Dual-format reality

Two independent formats describe the same eval cases, and neither tool reads the other's files:

- `evals/<skill>/<case-slug>/` — `prompt.md` + `graders/*.md` — is read by `claude plugin eval`.
- `skills/<skill>/evals/evals.json` — is read by the skill-creator plugin's own eval format.

They must be hand-maintained in pairs. Editing a rubric in one without mirroring the change into
the other is a silent drift: `claude plugin eval` and the skill-creator tooling will disagree
about what a case expects, and nothing enforces agreement except the case-count check in
`lint.py` (which only catches a count mismatch, not a content mismatch). Both currently hold 25
suites with equal case counts per skill.

## Writing a new case

Match an existing one. Constraints worth knowing before you start:

- Unknown frontmatter keys are a hard error, not a warning.
- Regex graders support only the `i` flag. No inline `(?i)`, no multiline — so `^`/`$` anchors
  cannot match a block that appears mid-message, and `.*` cannot cross a newline.
- Assert on strings the skill's `SKILL.md` actually mandates. A grader matching invented
  phrasing fails correct behavior, which is worse than no grader.
- Keep negative assertions out of patterns that a *correct* answer must contain. A
  `not_contains` on an env var name fails the answer that correctly names the missing variable.
- Prefer a deterministic grader wherever the assertion is literal. It is free and cannot be
  argued with.
- Grade the reply, not the filesystem. The sandbox a case runs in is empty and has no exec
  tools; a rubric that requires a file to exist or a command to have run can never pass
  honestly. Rewrite the assertion to grade what the final message states instead.
- Use the artifact-in-reply sentence (`Include the complete <artifact> in your reply.`,
  appended verbatim to the end of the prompt body) whenever a rubric needs to grade a produced
  artifact's content. Change nothing else in the prompt when adding it.
- Never write an always-passing grader. A `tool_used` grader with `min: 0, max: 0` on a tool
  that is not in `allowed_tools` passes unconditionally and inflates every other criterion's
  failure on that case — `lint.py` now rejects this pattern outright. If a case needs to assert
  that a destructive action was refused, write it as a FAIL bullet in `criteria.md` instead.
