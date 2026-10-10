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

94 cases across 19 skills. Case names are `<skill>-<slug>`, so one skill's suite runs with
`--case '<skill>-*'`.

## Running it

```sh
claude plugin eval .                      # whole suite, 3 runs per case per arm
claude plugin eval . --case 'deploy-*'    # one skill
claude plugin eval . --tag deploy         # same, by tag
claude plugin eval . --runs 1 --max-cost-usd 5
```

Budget before you run the whole thing: 94 cases x 3 runs x 2 ablation arms is ~560 agent runs.
`--runs 1` and `--case` keep that honest while iterating.

## Has it been run?

**No.** Every case here is unexecuted. `claude plugin eval` is in early access and was not
enabled on the account these were written on, so pass rates are unknown and no case has ever
been proven against a real run. Treat the suite as a specification of intended behavior, not
as a passing baseline. The first real run should be expected to surface broken cases.

## What the graders actually check

**Default focus is the final message.** No grader here inspects created files — there are no
`file_exists` graders and none use `focus: files`. A case is satisfied by a response that
*describes* the correct action; it does not require the action to have happened. That is
deliberate, and it is why every case grants only `[Read, Glob, Grep, Skill]`.

**Nine negative tool graders are inert by default.** Cases in `build`, `deploy`, `teardown`
and `test` carry graders asserting Bash or Edit was never called (`min: 0, max: 0`). Those
tools are not in any case's `allowed_tools`, so the assertion passes unconditionally and
carries no signal on a default run. They exist for runs made with an operator grant:

```sh
claude plugin eval . --allow-tools Bash Edit
```

Under that grant the assertions become live and will catch an agent that actually executes a
destructive command instead of refusing it. Every one of the nine is also backstopped by an
explicit FAIL bullet in its `criteria.md`, so the behavior is checked either way — by the judge
on a default run, mechanically under a grant.

**Skill-fired graders are indicators, not score.** `arm: with-only` keeps them out of the
with/without ablation delta. They answer "did the skill actually trigger" rather than "was the
answer good", which otherwise confounds a plugin win with a model that would have answered
well anyway.

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
