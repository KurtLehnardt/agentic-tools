---
type: llm
weight: 1
---

PASS if:
- Detects t01 has recovered (all 4/4 steps completed, no current problems)
- Deletes/removes stale NUDGE.md from t01 (was previously nudged for SLOW, now healthy)
- Console log shows deletion message: "Stale nudge removed: .claude/worktrees/t01-auth-middleware/NUDGE.md (worker recovered)"
- Does not write a new NUDGE.md for t01
- Assesses t02 normally (2/3 steps, healthy pace for Small task, no nudge needed)
- Does not re-nudge recovered workers

FAIL if:
- Fails to detect worker recovery
- Does not delete stale NUDGE.md despite worker recovery
- Skips deletion because NUDGE.md exists from prior check
- Writes new NUDGE.md to recovered worker
- Does not assess healthy t02 properly
- Re-nudges a recovered worker
