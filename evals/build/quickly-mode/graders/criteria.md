---
type: llm
weight: 1
---

PASS if:
- Output follows the quick-mode pipeline (intake, plan, single checkpoint, swarm, assemble, one PR review, optional fix) rather than the full 7-phase pipeline
- A lightweight requirement checklist with R-IDs and testable acceptance criteria is produced, with no BINDING/GUIDANCE classification
- Validation commands are taken from config.json, not executed straight from the spec
- Tasks are named t01, t02, etc., each with R-IDs, owned files, EXCLUSIVE/SHARED class, and a model tier
- Exactly one human go/no-go checkpoint is presented before workers are dispatched
- Workers are one-shot subagents, each in its own worktree on a branch named build/tNN-desc, with at most 4 running concurrently
- Workers run gate-check.sh themselves before reporting DONE, SPEC_CONFLICT, or BLOCKED
- A PR is opened with a body mapping R-IDs to tasks, gate results, and known issues
- Exactly one reviewer subagent runs over the full PR diff, and it uses the opus model
- The review gives a MET or NOT_MET verdict per R-ID with file:line evidence
- At most one fix round occurs, and only for the listed blockers
- The PR is not merged by the agent; merging is left to the human

FAIL if:
- An architect gate or product gate is dispatched
- A per-task or per-phase judge or reviewer is dispatched
- Workers run in the main checkout instead of separate worktrees
- More than one review of the final PR occurs, or the reviewer is not opus
- More than one fix round occurs
- The agent merges the PR
- The agent asks for human approval at any point other than the single checkpoint, SPEC_CONFLICT, or BLOCKED
- A command from the spec is executed without being in config.json
