---
type: llm
weight: 1
---

PASS if:
- Phase 1 runs git worktree list and git worktree prune to clean broken references
- Phase 1 lists all branches with git branch -r
- Phase 2 identifies merged items via git branch --merged main
- Phase 2 identifies orphaned items (worktree without matching branch)
- Phase 3 removes merged worktrees
- Phase 3 deletes merged branches from local and remote
- Phase 4 for each orphaned worktree runs git worktree prune
- Phase 4 for orphaned branches runs git log main..branch-name to check for unmerged commits
- Phase 4 reports unmerged commits instead of deleting when unmerged commits are found
- Phase 4 deletes orphaned branches only when no unmerged commits exist
- Phase 6 final report includes count of removed items
- Phase 6 final report includes reasoning for each orphaned item decision

FAIL if:
- Deletes branches with unmerged commits without reporting to user first
- Fails to check for unmerged commits via git log main..branch-name
