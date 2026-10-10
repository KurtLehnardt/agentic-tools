---
type: llm
weight: 1
---

PASS if:
- Reply describes the quick-mode pipeline (intake, plan, single checkpoint, swarm, assemble, one PR review, optional fix) rather than the full 7-phase pipeline
- Reply produces a lightweight requirement checklist with R-IDs and testable acceptance criteria, with no BINDING/GUIDANCE classification
- Reply states validation commands come from config.json, not executed straight from the spec
- Reply names tasks t01, t02, etc., each with R-IDs, owned files, EXCLUSIVE/SHARED class, and a model tier
- Reply may ask up to 3 batched clarifying questions during intake, before the checkpoint
- Reply presents exactly one human go/no-go checkpoint and stops there, rather than describing dispatch, merge, or review as having already happened
- Reply states the baseline is captured (gate-check.sh --integration on base_ref, saved as the baseline) after config detection and before planning or dispatch; any red checks on main are reported at the checkpoint, and workers are judged on delta
- Reply describes incremental assembly: a build/quick-<slug> assembly branch created from base_ref at the start of the swarm, each task merged into it once DONE and its gate passes, tasks without dependencies branching from base_ref, and a dependent task starting only after all its dependencies are merged and branching from the assembly branch
- Reply describes workers as one-shot subagents, each in its own worktree on a branch named build/tNN-desc, with at most 4 running concurrently
- Reply states workers run gate-check.sh themselves before reporting DONE, SPEC_CONFLICT, or BLOCKED
- Reply describes the integration gate running on the assembly branch, which is then pushed and opened as a PR with a body mapping R-IDs to tasks, gate results, and known issues
- Reply describes exactly one substantive reviewer subagent running over the full PR diff, using the opus model, with at most one re-dispatch allowed for a malformed review
- Reply states the review gives a MET or NOT_MET verdict per R-ID with file:line evidence
- Reply states at most one fix round occurs, scoped to the listed blockers
- Reply states the PR is not merged by the agent; merging is left to the human

FAIL if:
- Reply describes an architect gate or product gate being dispatched
- Reply describes a per-task or per-phase judge or reviewer being dispatched
- Reply describes workers running in the main checkout instead of separate worktrees
- Reply describes a second substantive review of the final PR (a single re-dispatch of a malformed review is not a second review), or names a reviewer other than opus
- Reply describes more than one fix round
- Reply states the agent merges the PR itself
- Reply asks for human approval at any point other than the single checkpoint, the batched intake questions (max 3), SPEC_CONFLICT, or BLOCKED
- Reply describes workers being dispatched before the baseline is captured, or a dependent task starting before all its dependencies are merged into the assembly branch
- Reply describes executing a command from the spec that is not in config.json
- Reply claims dispatch, worker completion, review, or merge already happened in this turn rather than describing the plan and stopping at the checkpoint
