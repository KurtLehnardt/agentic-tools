---
type: llm
weight: 1
---

PASS if:
- Discovers all 4 build/* worktrees (t01-database, t02-api, t03-auth, t04-frontend)
- Assesses progress for each by reading git history (commits, file changes, time since last commit)
- Detects problem types (STALLED, SLOW, SCOPE DRIFT, REPEATED FAILURE, NO PROGRESS, BLOCKED) where applicable
- Writes NUDGE.md atomically (using .NUDGE.md.tmp → mv pattern) to problem workers only
- Console report uses tabular format showing task ID, step progress (N/M steps), last commit time, and problem status

FAIL if:
- Modifies any code files or git state
- Writes NUDGE.md to workers with healthy progress
- Does not discover all 4 workers
- Does not assess progress using git history
- Console report lacks tabular format or required columns
