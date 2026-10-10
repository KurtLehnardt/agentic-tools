---
type: llm
weight: 1
---

PASS if:
- Output includes all five sections (REPOSITORY, ACTIVE WORKTREES, RECENT SCORES, BLOCKERS, ENVIRONMENT)
- Dashboard is identical in completeness and detail to formal /status request
- All sections contain real data from git, file system, and environment checks
- Casual phrasing of input does not reduce output quality or detail
- Worktree names and review scores match actual disk state

FAIL if:
- Lowered output quality based on informal input register
- Skipped sections due to casual phrasing
- Abbreviated output instead of providing full dashboard
- Reported incomplete or summary-level information instead of detailed status
