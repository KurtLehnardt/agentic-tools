---
type: llm
weight: 1
---

PASS if:
- Recognizes /teardown trigger phrase
- Executes all six phases: inventory, categorization, cleanup, orphan handling, archival, report
- Tone of explanation matches casual input style
- Performs merge status check before deletion (via git branch --merged main)
- Categorizes items as merged, active, orphaned, or stale
- Removes merged worktrees and branches (both local and remote)
- Archives plan files to .claude/archive/plans/
- Updates SHARED_CONTEXT.md if present
- Final report includes counts and disk recovered

FAIL if:
- Assumes all items are safe to delete without checking merge status
