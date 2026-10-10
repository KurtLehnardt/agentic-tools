---
type: llm
weight: 1
---

PASS if:
- Output includes REPOSITORY section with current branch and commit SHA
- Output includes ACTIVE WORKTREES section with count from git worktree list
- Output includes RECENT SCORES section with architect, executive, critic scores
- Output includes BLOCKERS section with blocked task names and reasons
- Output includes ENVIRONMENT section with connection status checks
- Review scores match values in roadmap-progress.json, not fabricated values
- Worktree count is accurate to git worktree list output (zero is valid)

FAIL if:
- Reported build states (passing/failing) not actually executed
- Invented test results or test counts not present in logs
- Reported review scores not in roadmap-progress.json
- Reported phantom worktrees (count greater than git worktree list shows)
- Missing any of the five required sections
