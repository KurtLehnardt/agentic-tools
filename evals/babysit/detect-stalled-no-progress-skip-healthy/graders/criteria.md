---
type: llm
weight: 1
---

PASS if:
- Detects t01 as STALLED (12 mins idle with no uncommitted changes)
- Does NOT include NUDGE.md content for t02 (making progress, files in scope)
- Detects t03 as NO PROGRESS (25 mins active, zero commits)
- Reply includes the complete NUDGE.md content for t01, using the STALLED-specific template
- Reply includes the complete NUDGE.md content for t03, using the NO PROGRESS-specific template
- Console report shows t01 status as STALLED, t02 status as healthy (✓), t03 status as NO PROGRESS
- Does not confuse elapsed time (worktree age) with stall time (time since last commit)

FAIL if:
- Fails to detect t01 as STALLED
- Includes NUDGE.md content for healthy t02
- Fails to detect t03 as NO PROGRESS
- Uses the generic nudge template instead of the problem-specific templates for t01 or t03
- Does not distinguish between stall time and elapsed time
- Console report lacks clear problem status indicators
