---
type: llm
weight: 1
---

PASS if:
- States that phase 1 names git worktree list and git worktree prune as the steps used to clean broken references
- States that phase 1 lists all branches, naming git branch -r
- States that phase 2 identifies merged items via git branch --merged main
- States that phase 2 identifies orphaned items (worktree without matching branch)
- States that phase 3 removes merged worktrees
- States that phase 3 deletes merged branches, local and remote
- States that phase 4, for each orphaned worktree, runs git worktree prune
- States that phase 4, for orphaned branches, names git log main..branch-name as the check for unmerged commits
- States that phase 4 reports unmerged commits instead of deleting when unmerged commits are found
- States that phase 4 deletes orphaned branches only when no unmerged commits exist
- Phase 6 final report includes count of removed items
- Phase 6 final report includes reasoning for each orphaned item decision

FAIL if:
- States or implies branches with unmerged commits were deleted without reporting to the user first
- Does not mention checking for unmerged commits via git log main..branch-name
