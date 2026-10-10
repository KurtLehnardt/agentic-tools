---
type: llm
weight: 1
---

PASS if:
- Detects t01 has recovered (all 4/4 steps completed, no current problems)
- States that the stale NUDGE.md for t01 is removed (it was previously nudged for SLOW, now healthy)
- Console log shows a deletion message: "Stale nudge removed: .claude/worktrees/t01-auth-middleware/NUDGE.md (worker recovered)"
- Does not describe writing a new NUDGE.md for t01
- Assesses t02 normally (2/3 steps, healthy pace for Small task, no nudge needed)
- Does not describe re-nudging recovered workers

FAIL if:
- Fails to detect worker recovery
- Does not state the stale NUDGE.md is removed despite worker recovery
- States the deletion is skipped because NUDGE.md exists from a prior check
- States that a new NUDGE.md is written for the recovered worker
- Does not assess healthy t02 properly
- Describes re-nudging a recovered worker
