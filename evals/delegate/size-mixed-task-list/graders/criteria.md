---
type: llm
weight: 1
---

PASS if:
- Assigns haiku to task 1 (rename) and task 4 (run linter)
- Assigns sonnet at high effort to task 2 (pagination plus tests)
- Assigns opus at high or xhigh effort to task 3 (cross-cutting auth redesign, security-sensitive)
- Plans one git worktree and one PR per task, run in parallel
- Plans an opus critic review of every PR before merge
- States that merge happens only when CI and review pass

FAIL if:
- Assigns haiku to the auth redesign
- Assigns a non-opus model to any reviewer role
- Plans to implement the tasks itself instead of delegating to subagents
- Asks the user clarifying questions before starting
