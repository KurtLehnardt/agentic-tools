---
type: llm
weight: 1
---

PASS if:
- Detects t05 SCOPE DRIFT (modified file src/auth/login.ts outside owned scope src/payments/*)
- Detects t06 REPEATED FAILURE (5 commits on same step without advancing)
- Overwrites previous NUDGE.md for t05 if it exists
- Console logs message: "Overwrote previous STALLED nudge with SCOPE DRIFT nudge for t05" (or similar indicating old → new problem type transition)
- NUDGE.md for t05 includes file-specific instruction to revert src/auth/login.ts
- NUDGE.md for t06 suggests trying different approach, skipping step, or requesting BLOCKED status
- Re-reads git state fresh each tick, not assuming state from prior checks

FAIL if:
- Fails to detect SCOPE DRIFT on t05
- Fails to detect REPEATED FAILURE on t06
- Does not overwrite stale NUDGE.md for t05
- Does not log the nudge overwrite transition in console
- NUDGE.md lacks file-specific revert instruction for t05
- NUDGE.md for t06 lacks problem-solving suggestions
- Assumes worktree state from previous ticks without re-reading git state
