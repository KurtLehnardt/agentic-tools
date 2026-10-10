---
type: llm
weight: 1
---

PASS if:
- Distinguishes plan file handling: states PLAN-*.md files were archived (moved to .claude/archive/plans/)
- States the .claude/archive/plans/ directory was created if needed
- States PRD-*.md stays in the project root (reference docs, not ephemeral)
- Identifies active vs completed worktrees via phase 2 categorization
- Active items defined as: not merged OR recent commits OR unchecked plan steps
- States that only completed/merged worktrees and branches were removed
- States that active worktrees t07 and t08 were left untouched
- Final report names archived plan files (PLAN-t01.md, PLAN-t02.md)
- Final report names kept PRD file (PRD-main.md)
- Final report names kept worktrees (t07, t08)
- Final report confirms all cleanup completed

FAIL if:
- States or implies worktrees with unmerged branches were deleted
- States or implies PRD-*.md files were deleted or archived
- States or implies active worktrees t07 and t08 were removed
