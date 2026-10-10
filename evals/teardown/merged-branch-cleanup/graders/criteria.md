---
type: llm
weight: 1
---

PASS if:
- States that all six phases were covered, in order: inventory, categorization, cleanup, orphan handling, archival, report
- States that phase 1 inventory named git worktree list, git branch, and git branch --merged main
- States that phase 2 categorized the named items as MERGED
- States that phase 3 removed the worktrees (.claude/worktrees/t01, .claude/worktrees/t02, .claude/worktrees/t03)
- States that phase 3 deleted the local branches (build/t01-auth, build/t02-payments, build/t03-logging)
- States that phase 3 deleted the corresponding remote branches
- States that phase 5 archived plan files to the .claude/archive/plans/ directory
- States that phase 5 updated SHARED_CONTEXT.md, if present
- Phase 6 final report includes exact count of removed worktrees
- Phase 6 final report includes exact count of removed branches
- Phase 6 final report includes estimated disk space recovered

FAIL if:
- States or implies unmerged branches were deleted
- States or implies worktrees with uncommitted changes were force-removed
