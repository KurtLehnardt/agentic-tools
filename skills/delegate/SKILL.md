---
name: delegate
description: "Lightweight everyday orchestration: split an ad-hoc task list into independent pieces, size each to the right model, run each in its own git worktree with its own PR, have an opus critic review every PR, fix non-nitpick findings, and merge when CI and review pass. No spec ledger and no gates pipeline. Trigger: delegate this, split this up, spin up subagents, divide and conquer, dispatch workers, fix all findings with a subagent team. Args: --no-merge, --min <severity>, --max-parallel N."
user-invocable: true
---

# /delegate: Everyday Divide and Conquer

You are the orchestrator. You do not implement tasks yourself. You decompose the work, brief subagents, track their PRs, and report. This skill replaces the long boilerplate paragraph about dispatchers, model sizes, worktrees, reviews and merging, so the user never has to type it again.

## When to use it

Use /delegate for an ad-hoc list of tasks, a pile of review findings, or any "go do all of this" request. It is the lightweight sibling of `/build`. `/build` starts from a spec, keeps a requirements ledger, and runs a gates pipeline. `/delegate` has no spec ledger and no gates pipeline. If the user hands you a spec, contract, or PRD and wants a full implementation, point them to `/build` instead.

## Arguments

- `--no-merge`: stop after the final review passes and leave the PRs open for the user.
- `--min <severity>`: lowest finding severity the fix subagent must address. Default is `medium`. Accepted values are `low`, `medium`, `high`, `critical`. Anything below the threshold is reported but not fixed.
- `--max-parallel N`: cap on concurrently running workers. Default is no cap beyond what the machine and API limits allow.

## Which model for which job

| Job | Model | Effort |
|-----|-------|--------|
| Simple or mechanical work: renames, lookups, small single-file edits, file ops, running commands | haiku | default |
| Medium work: normal features, bug fixes, tests, changes touching 1 to 3 files | sonnet | high |
| Complex work: architecture, cross-cutting changes, tricky debugging, security-sensitive code | opus | high or xhigh |
| Every review, critic, and final-review role | opus (fable is an acceptable alternative for top-tier review) | high or xhigh |

Two rules apply on top of the table. First, escalate one tier when a worker fails or stalls: haiku becomes sonnet, sonnet becomes opus. Second, never downgrade a reviewer. A reviewer is always opus or fable, even when the code under review was written by haiku.

## Flow

1. **Decompose.** Break the request into tasks that can run independently. If two tasks touch the same files, merge them into one task or order them explicitly.
2. **Size.** Assign each task a model and effort from the table above. Write the choice next to the task so the user can see it.
3. **Run in parallel.** Start one subagent per task, each in its own git worktree on its own branch. Respect `--max-parallel`. For large lists, use dispatcher subagents: you brief a dispatcher, and the dispatcher briefs and tracks its own workers. Dispatchers follow the same sizing table.
4. **One PR per task.** Each worker opens its own PR when its work is done and returns the PR URL.
5. **Critic review.** For every PR, start an opus critic subagent. The critic reviews the diff, rates each finding by severity, and returns a list.
6. **Fix.** For each PR with findings at or above the `--min` threshold, start a fix subagent. Size it with the table. It fixes those findings on the same branch and pushes. Nitpicks and findings below the threshold are not fixed.
7. **Re-review.** The critic reviews the updated PR again. Repeat steps 6 and 7 until no findings remain at or above the threshold. Stop after three rounds and report the PR as blocked rather than looping forever.
8. **Merge.** When CI is green and the review passes, merge the PR and clean up its worktree. Skip this step under `--no-merge`.
9. **Report.** Give the user a short table with one row per task: PR link, model used, rounds of review, and final status.

The per-PR critique, fix, and merge loop in steps 5 to 8 is specified in detail in `/review-pr`. Use that skill for the loop instead of re-deriving it here. For a final sign-off on large batches, add one opus review at xhigh effort across the merged result.

## Autonomy rule

No subagent may block waiting for input from the user, and neither may you. When a decision is ambiguous, pick the most conservative reasonable option, record the assumption in the PR description, and continue. Only destructive or irreversible actions pause for confirmation: force-pushes, deleting branches that hold unmerged work, dropping data, production deploys, and anything that spends money. In that case, ask once, in plain sentences, and let the other tasks keep running.

## Subagent brief template

Every subagent prompt contains these four parts.

- **Goal:** one sentence describing the outcome.
- **Inputs:** exact files, PR links, findings, or context the agent needs. Do not make it rediscover what you already know.
- **Output format:** what to return, such as a PR URL, a findings list with severities, or a short summary.
- **Constraints:** the worktree path and branch, the files it may touch, time or scope limits, the autonomy rule, and the instruction not to wait for the user.

Relay the user's voice preference in every brief. If the user prefers terse output (the ultracave voice), tell each subagent to narrate in terse fragments. Persisted text such as code, comments, commit messages, and PR descriptions must still be written in full plain sentences. A fresh subagent does not inherit this preference, so say it explicitly each time.

## Rules

- Never implement a task yourself. If delegation fails twice for one task, report the error and move on to the others.
- Keep each worker's scope narrow. A worker that discovers extra work reports it and does not widen its own task.
- Merge only PRs whose CI is green and whose last review passed. Never merge on a partial pass.
