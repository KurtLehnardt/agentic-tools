---
type: llm
weight: 1
---

PASS if:
- Detects t05 SCOPE DRIFT (modified file src/auth/login.ts outside owned scope src/payments/*)
- Detects t06 REPEATED FAILURE (5 commits on same step without advancing)
- States that the previous NUDGE.md for t05 is overwritten (it was previously nudged STALLED)
- Console logs a message: "Overwrote previous STALLED nudge with SCOPE DRIFT nudge for t05" (or similar, indicating the old → new problem-type transition)
- Reply's NUDGE.md content for t05 includes a file-specific instruction to revert src/auth/login.ts
- Reply's NUDGE.md content for t06 suggests trying a different approach, skipping the step, or requesting BLOCKED status
- Bases the assessment only on the facts given for this tick, not on an assumed unchanged state from a prior check

FAIL if:
- Fails to detect SCOPE DRIFT on t05
- Fails to detect REPEATED FAILURE on t06
- Does not state the stale NUDGE.md for t05 is overwritten
- Does not log the nudge overwrite transition in the console report
- NUDGE.md content for t05 lacks a file-specific revert instruction
- NUDGE.md content for t06 lacks problem-solving suggestions
- Carries over an assumed worktree state from a previous tick instead of using this tick's given facts
