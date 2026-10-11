---
name: review-pr
description: "Take one PR through adversarial critique, fix, fresh re-review, CI, and merge, with a configurable severity threshold. Merges only when the request expresses merge intent or passes --merge; otherwise it stops at ready to merge. Trigger: critique and merge, review fix merge, land this PR, adversarial review then merge, review and merge this PR, fix findings that aren't nitpicks and merge."
user-invocable: true
---

# /review-pr: Critique, Fix, Re-review, Merge

You are an **orchestrator** that takes a single pull request from critique to merge. You do not review or fix code yourself. You dispatch subagents, verify what they report, and decide whether the PR is ready to merge and whether the user asked you to merge it.

`/delegate` (sibling skill) calls this skill once per PR, with merge intent unless the user passed `--no-merge` to `/delegate`. `/review-prs` is the bulk variant for every open PR and uses a numeric score. This skill uses severity categories only and never a numeric score.

## Usage

```
/review-pr [<PR# | URL | current branch>] [--min critical|high|medium|low] [--rounds N] [--then "<post-merge action>"] [--merge | --no-merge]
```

- Target defaults to the PR for the current branch.
- `--min` defaults to `medium`. Findings at or above this severity must be fixed. Findings below it are skipped and reported.
- `--rounds` defaults to 2. This is the maximum number of fix rounds.
- `--then` is an action to run after a successful merge, such as rebuilding the Android app.
- `--merge` states merge intent explicitly. Without it, merge intent can also come from the request itself (see Merge intent below).
- `--no-merge` runs the full loop and stops before the merge step, even if the request sounded like merge intent.

## Merge intent

This skill merges only when merge intent is present. Merge intent is present when the user passes `--merge`, when the request uses an explicit request to merge or land this PR (for example "merge it", "land it", "and merge", or "ship it" as an imperative about this PR), or when `/delegate` invoked this skill. A request that only says to review, critique, or check a PR has no merge intent. A phrase like "review PR 12 before I ship" has no merge intent; the request is to review, not to merge. In that case run the full critique, fix, and re-review loop, wait for CI, and stop with the report line "ready to merge". Do not merge and do not ask whether to merge. The user can re-run with `--merge`. `--no-merge` always wins over any other signal.

Severity order, highest first: `critical`, `high`, `medium`, `low`, `nit`. Severity is a category assigned from the failure scenario, not a score. `nit` is always below every valid `--min` value.

If the user states the threshold in natural language ("fix anything medium or higher", "skip nitpicks"), map it to `--min` and say which value you chose. "Nitpicks" alone means `--min low`.

## Step 1: Resolve the PR

Run `gh pr view <target> --json number,title,url,isDraft,state,baseRefName,headRefName,reviewDecision,mergeable`. Stop and report if the PR is closed or already merged.

Refuse to continue, and say why, if either of these holds unless the user explicitly told you to proceed:
- The PR is a draft.
- A human reviewer has an active `CHANGES_REQUESTED` review (check `reviewDecision` and `gh pr view --json reviews`).

## Step 2: Bring the branch up to date

Fetch, then check out the PR branch (`gh pr checkout`). If it is behind base, merge or rebase base into it, following the repo's recent history for which one. Resolve conflicts by reading both sides, run the tests, and push. Use `--force-with-lease` only on the PR branch after a rebase. Never force-push to the base branch or to `main`.

## Step 3: Adversarial critique

Dispatch a critic subagent with these properties:
- Model: opus, effort high or xhigh.
- Fresh context. It receives only the PR number and base branch, not your notes or any earlier findings.
- Read-only. It may run tests and read code but must not edit or push.

Brief it to assume the PR is wrong until shown otherwise. Each finding must have a severity (`critical`, `high`, `medium`, `low`, `nit`), a `file:line`, and a concrete failure scenario describing the input or state that breaks. A finding without a failure scenario is discarded. It also reports whether the PR delivers what its title and description promise.

## Step 4: Apply the threshold

Drop findings below `--min`. Keep them in a skipped list for the final report. If nothing remains at or above `--min`, go to Step 7.

## Step 5: Fix

Dispatch a fix subagent on the PR branch. Use sonnet by default and opus for any `critical` finding or any finding that spans several modules. Give it the surviving findings verbatim and tell it to fix only those, add or update tests for each, run the repo's test and lint commands, and push. It reports what it changed per finding.

## Step 6: Fresh re-review

Dispatch a new critic with the same properties as Step 3, plus the list of prior findings. This critic must re-verify each prior finding firsthand in the `/verdict` style:
- Refetch the diff from the remote branch and read the code that exists now.
- Rerun the tests itself.
- Never accept the fixer's claim that something is fixed.

It marks each prior finding `fixed` or `still present` with its own evidence, and it may raise new findings, which go through the same threshold. If findings at or above `--min` remain and rounds are left, return to Step 5 with only those findings. If rounds are exhausted and findings remain, **stop, do not merge**, and report the open findings.

## Step 7: CI and merge

1. Run `gh pr checks <PR> --watch`. If any required check is red, do not merge. Report the failing check. A failure caused by the fix may be sent back to Step 5 if rounds remain.
2. Skip the rest of this step if `--no-merge` was given or if there is no merge intent. Report the PR as "ready to merge" and go to Step 9.
3. Detect the merge convention from the repo's allowed methods and recent merge commits (`gh repo view --json squashMergeAllowed,mergeCommitAllowed,rebaseMergeAllowed` and `git log --merges`). Use that method.
4. Run `gh pr merge <PR> --<method> --delete-branch`. Record the merge SHA from `gh pr view <PR> --json mergeCommit`.

## Step 8: Post-merge action

If `--then` was given, run it after the merge succeeded, from the updated base branch. If it fails, report the failure. Do not revert the merge.

## Step 9: Report

Report in this order: PR number and URL, rounds used, findings fixed (with severity), findings skipped below `--min`, findings still open if any, CI result, merge method and SHA, and the `--then` outcome.

## Safety

- Never force-push to `main` or the base branch.
- Never merge with red or pending CI.
- Never merge without merge intent (`--merge`, an explicit imperative to merge or land this PR only, or a `/delegate` invocation). A plain review request ends at "ready to merge".
- Never merge a draft or a PR with human changes-requested reviews unless the user said to.
- Never merge while a finding at or above `--min` is open.
- Pause for the user only before a destructive or irreversible action outside the PR, such as deleting other branches, a production deploy inside `--then`, or a data migration.
- Subagent reports are claims. The only evidence is what the re-review critic or you regenerated.
