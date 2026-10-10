---
type: llm
weight: 1
---

PASS if:
- Recognizes /teardown trigger phrase
- States that all six phases were covered: inventory, categorization, cleanup, orphan handling, archival, report
- Tone of explanation matches casual input style
- States that a merge status check was performed before deletion (naming git branch --merged main)
- Categorizes items as merged, active, orphaned, or stale
- States that merged worktrees and branches were removed (both local and remote)
- States that plan files were archived to .claude/archive/plans/
- States that SHARED_CONTEXT.md was updated, if present
- Final report includes counts and disk recovered

FAIL if:
- States or implies all items were treated as safe to delete without checking merge status
