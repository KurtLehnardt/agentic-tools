---
type: llm
weight: 1
---

PASS if:
- Detects t01 as STALLED (12 mins idle with no uncommitted changes)
- Does NOT write NUDGE.md for t02 (making progress, files in scope)
- Detects t03 as NO PROGRESS (25 mins active, zero commits)
- Writes NUDGE.md for t01 with STALLED-specific template
- Writes NUDGE.md for t03 with NO PROGRESS-specific template
- Console report shows t01 status as STALLED, t02 status as healthy (✓), t03 status as NO PROGRESS
- Does not confuse elapsed time (worktree age) with stall time (time since last commit)

FAIL if:
- Fails to detect t01 as STALLED
- Writes NUDGE.md to healthy t02
- Fails to detect t03 as NO PROGRESS
- Uses generic nudge template instead of problem-specific templates
- Does not distinguish between stall time and elapsed time
- Console report lacks clear problem status indicators
