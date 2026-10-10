---
type: llm
weight: 1
---

PASS if:
- Distinguishes plan file handling: archives PLAN-*.md files (moved to .claude/archive/plans/)
- Creates .claude/archive/plans/ directory if needed
- Keeps PRD-*.md in project root (reference docs, not ephemeral)
- Identifies active vs completed worktrees via phase 2 categorization
- Active items defined as: not merged OR recent commits OR unchecked plan steps
- Removes only completed/merged worktrees and branches
- Leaves active worktrees t07 and t08 untouched
- Final report names archived plan files (PLAN-t01.md, PLAN-t02.md)
- Final report names kept PRD file (PRD-main.md)
- Final report names kept worktrees (t07, t08)
- Final report confirms all cleanup completed

FAIL if:
- Deletes worktrees if their branches are unmerged
- Deletes or archives PRD-*.md files
- Removes active worktrees t07 and t08
