---
type: llm
weight: 1
---

PASS if:
- BLOCKERS section is emphasized and detailed
- All five sections (REPOSITORY, ACTIVE WORKTREES, RECENT SCORES, BLOCKERS, ENVIRONMENT) included
- Each blocked task is explicitly named (e.g., 't03-frontend')
- Each blocker shows its reason (dependency on another task or rejected score)
- Each blocker cites the blocking criterion (architect rejected, critic score X for reason)
- Blockers match data in roadmap-progress.json
- If no blockers exist in the file, reports zero blockers

FAIL if:
- Invented blockers not present in roadmap-progress.json
- Failed to name specific blocked tasks
- Omitted blocker reasons or blocking criteria
- Suggested workarounds without data backing them
- Missing other sections due to focus on blockers
