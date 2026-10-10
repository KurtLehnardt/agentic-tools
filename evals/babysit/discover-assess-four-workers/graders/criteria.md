---
type: llm
weight: 1
---

PASS if:
- Discovers all 4 build/* worktrees (t01-database, t02-api, t03-auth, t04-frontend)
- Assesses progress for each based on commits, file changes, and time since last commit
- Names the problem type (STALLED, SLOW, SCOPE DRIFT, REPEATED FAILURE, NO PROGRESS, BLOCKED) for any worker where one applies
- Reply shows the atomic write commands (heredoc to .NUDGE.md.tmp, then `mv` to NUDGE.md) for problem workers only
- Console report uses tabular format showing task ID, step progress (N/M steps), last commit time, and problem status

FAIL if:
- Describes modifying any code files or git state
- Shows atomic write commands or NUDGE.md content for workers with healthy progress
- Does not discover all 4 workers
- Does not assess progress using commit/file-change history
- Console report lacks tabular format or required columns
