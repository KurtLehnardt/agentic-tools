---
type: llm
weight: 1
---

PASS if:
- Executes all six phases in order: inventory, categorization, cleanup, orphan handling, archival, report
- Phase 1 inventory includes git worktree list, git branch, and git branch --merged main
- Phase 2 categorizes items as MERGED
- Phase 3 removes worktrees (.claude/worktrees/t01, .claude/worktrees/t02, .claude/worktrees/t03)
- Phase 3 deletes local branches (build/t01-auth, build/t02-payments, build/t03-logging)
- Phase 3 deletes corresponding remote branches
- Phase 5 archives plan files to .claude/archive/plans/ directory
- Phase 5 updates SHARED_CONTEXT.md if present
- Phase 6 final report includes exact count of removed worktrees
- Phase 6 final report includes exact count of removed branches
- Phase 6 final report includes estimated disk space recovered

FAIL if:
- Deletes unmerged branches
- Force-removes worktrees with uncommitted changes
