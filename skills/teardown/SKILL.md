---
name: teardown
description: "Clean up completed builds: remove worktrees, delete merged branches, archive plan files, and reset factory state. Trigger: clean up, teardown, remove worktrees, clean factory."
user-invocable: true
---

# /teardown — Factory Cleanup

You are an **orchestrator** cleaning up after builds complete. Worktrees accumulate, branches linger, plan files scatter. This skill removes everything that's been merged and archives what should be preserved.

## What This Skill Does

1. Identifies all worktrees, branches, and plan files
2. Categorizes each as: merged (safe to remove), active (keep), orphaned (investigate)
3. Removes merged worktrees and branches
4. Archives completed plan files
5. Reports what was cleaned and what remains

## Phase 1: INVENTORY

Gather the full state without modifying anything:

```bash
# All worktrees
git worktree list

# All local branches
git branch

# All remote tracking branches
git branch -r

# Branches merged into main
git branch --merged main

# Branches NOT merged into main
git branch --no-merged main
```

Also scan for:
- `.claude/worktrees/` directory contents
- `../worktrees/` directory contents
- `PLAN-*.md` files in any worktree
- `PRD-*.md` files in project root
- `SHARED_CONTEXT.md` entries referencing completed tasks

## Phase 2: CATEGORIZE

For each worktree/branch, determine status:

### MERGED (safe to remove):
- Branch has been merged into main
- No uncommitted changes in worktree
- All plan steps are checked off
- Critic review score >= 9.5

### ACTIVE (keep):
- Branch has NOT been merged
- Worktree has recent commits (< 24 hours)
- Plan has unchecked steps
- Worker may still be running

### ORPHANED (investigate):
- Branch exists but no worktree found
- Worktree exists but no branch found
- No commits in > 7 days
- Plan exists but no corresponding worktree

### STALE (confirm before removing):
- Branch not merged, no commits in > 48 hours
- Worktree with uncommitted changes and no recent activity
- These require **human confirmation** before removal

## Phase 3: CLEANUP (merged items only)

For each MERGED item, in order:

```bash
# 1. Remove worktree
git worktree remove .claude/worktrees/tNN-description

# 2. Delete local branch
git branch -d build/tNN-description

# 3. Delete remote branch (if exists)
git push origin --delete build/tNN-description
```

### Plan file archival:
- Move completed `PLAN-*.md` to `.claude/archive/plans/` (create if needed)
- Keep `PRD-*.md` in project root (they're reference docs, not ephemeral)

### SHARED_CONTEXT.md update:
- Move completed tasks from "Active Worktrees" to "Recently Merged"
- Prune "Recently Merged" entries older than 30 days

## Phase 4: ORPHAN HANDLING

For each ORPHANED item:

```bash
# Check if branch has unmerged work
git log main..build/tNN-description --oneline

# If no unmerged commits → safe to delete
git branch -D build/tNN-description

# If unmerged commits exist → report to human
echo "Branch build/tNN-description has N unmerged commits. Keep or delete?"
```

For orphaned worktrees with no branch:
```bash
git worktree prune  # Git's built-in cleanup for broken worktree references
```

## Phase 5: STALE ITEM REPORT

Do NOT auto-delete stale items. Report them:

```
Stale items (require human decision):
  ⚠ build/t05-payments: last commit 3 days ago, 4 uncommitted files
    → Keep working? Or abandon?
  ⚠ .claude/worktrees/t07-compliance: no branch found, has 12 modified files
    → Orphaned worktree. Review changes before deleting?
```

## Phase 6: REPORT

```
Factory Cleanup Complete:

  Removed:
    ✓ 3 worktrees (.claude/worktrees/t01, t02, t03)
    ✓ 3 local branches (build/t01, build/t02, build/t03)
    ✓ 3 remote branches
    ✓ 3 plan files archived to .claude/archive/plans/

  Kept (active):
    • build/t04-api-routes (worker in progress, 6/10 steps done)

  Needs attention:
    ⚠ build/t05-payments: stale 3 days, human decision needed
    ⚠ Orphaned worktree: .claude/worktrees/t07-compliance

  Disk space recovered: ~45 MB
  Remaining worktrees: 1 active, 1 stale
```

## Safety Rules

1. **Never delete unmerged branches without human confirmation.**
2. **Never force-remove worktrees with uncommitted changes** unless the human explicitly says to.
3. **Always `git worktree prune` before listing** to clean broken references first.
4. **Archive, don't delete** plan files — they're useful for future reference.
5. **Update SHARED_CONTEXT.md** so the next planner has accurate state.
6. **Check for running agents** before removing a worktree — a worker may still be executing.
