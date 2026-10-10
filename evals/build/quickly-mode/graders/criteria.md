---
type: llm
weight: 1
---

PASS if:
- Output follows the quick-mode pipeline (intake, plan, single checkpoint, swarm, assemble, one PR review, optional fix) rather than the full 7-phase pipeline
- A lightweight requirement checklist with R-IDs and testable acceptance criteria is produced, with no BINDING/GUIDANCE classification
- Validation commands are taken from config.json, not executed straight from the spec
- Tasks are named t01, t02, etc., each with R-IDs, owned files, EXCLUSIVE/SHARED class, and a model tier
- Up to 3 batched clarifying questions may be asked during intake, before the checkpoint
- Exactly one human go/no-go checkpoint is presented before workers are dispatched
- The baseline is captured (gate-check.sh --integration on base_ref saved as the baseline) after config detection and before planning or dispatch; any red checks on main are reported at the checkpoint, and workers are judged on delta
- Dependency handling uses incremental assembly: a build/quick-<slug> assembly branch is created from base_ref at the start of the swarm, each task is merged into it once DONE and its gate passes, tasks without dependencies branch from base_ref, and a task with dependencies starts only after all its dependencies are merged and branches from the assembly branch
- Workers are one-shot subagents, each in its own worktree on a branch named build/tNN-desc, with at most 4 running concurrently
- Workers run gate-check.sh themselves before reporting DONE, SPEC_CONFLICT, or BLOCKED
- The integration gate runs on the assembly branch, which is then pushed and opened as a PR with a body mapping R-IDs to tasks, gate results, and known issues
- Exactly one substantive reviewer subagent runs over the full PR diff, and it uses the opus model; one re-dispatch of a malformed review is allowed
- The review gives a MET or NOT_MET verdict per R-ID with file:line evidence
- At most one fix round occurs, and only for the listed blockers
- The PR is not merged by the agent; merging is left to the human

FAIL if:
- An architect gate or product gate is dispatched
- A per-task or per-phase judge or reviewer is dispatched
- Workers run in the main checkout instead of separate worktrees
- A second substantive review of the final PR occurs (a single re-dispatch of a malformed review is not a second review), or the reviewer is not opus
- More than one fix round occurs
- The agent merges the PR
- The agent asks for human approval at any point other than the single checkpoint, the batched intake questions (max 3), SPEC_CONFLICT, or BLOCKED
- Workers are dispatched before the baseline is captured, or a dependent task is started before all its dependencies are merged into the assembly branch
- A command from the spec is executed without being in config.json
