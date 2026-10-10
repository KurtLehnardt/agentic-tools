---
type: llm
weight: 1
---

PASS if:
- REPOSITORY section reports current branch and latest commit only
- ACTIVE WORKTREES section reports zero or 'none', accurately reflecting git worktree list
- RECENT SCORES section is omitted or explicitly empty (no roadmap file exists)
- BLOCKERS section is empty (no data to read)
- ENVIRONMENT shows actual connection status checks
- Clearly indicates what is absent rather than fabricating state
- No phantom worktrees, tasks, or build history reported

FAIL if:
- Fabricated phantom worktrees or active builds
- Invented historical task data or phantom task names
- Hallucinated build state, test results, or commit activity
- Invented review scores when roadmap-progress.json does not exist
- Populated BLOCKERS section with fabricated dependencies
- Suggested phantom worktree activity or pending work
- Confused empty state with populated state
