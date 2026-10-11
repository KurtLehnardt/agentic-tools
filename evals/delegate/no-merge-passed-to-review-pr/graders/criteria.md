---
type: llm
weight: 1
---

PASS if:
- Maps the request to `--no-merge` and plans to stop after the final review passes
- Plans one worktree and one PR per task
- Says the PRs stay open for the user and are reported as ready to merge
- Says the per-PR loop runs through `/review-pr` with `--no-merge`

FAIL if:
- Plans to merge either PR
- Plans to implement the tasks itself instead of delegating to subagents
