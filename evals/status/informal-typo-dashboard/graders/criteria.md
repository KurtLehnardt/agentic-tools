---
type: llm
weight: 1
---

PASS if:
- Intent is correctly parsed from informal phrasing with typos
- Complete status dashboard returned with all five sections
- All sections contain accurate data from git, file system, and environment
- Worktree names match actual disk state
- Review scores match roadmap-progress.json values
- No reduction in output quality despite casual input

FAIL if:
- Degraded accuracy or completeness due to informal input register
- Assumed missing data instead of reading from available files
- Failed to parse intent from sloppy phrasing
- Reported partial or summary output instead of full dashboard
- Mismatched worktree names or scores against actual disk state
