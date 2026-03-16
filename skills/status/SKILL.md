---
name: status
description: "Show factory dashboard: active builds, worktree status, review scores, blockers, and project health. Trigger: status, dashboard, what's running, factory status, show progress."
user-invocable: true
---

# /status — Factory Dashboard

You are an **orchestrator** producing a snapshot of the entire code factory's state. No agents are dispatched for this skill — you read local state and report.

## What This Skill Shows

A single consolidated view of:
1. Active worktrees and what's running in each
2. Recent build scores and outcomes
3. Blocked tasks and why
4. Environment health
5. Repository state

## Data Sources

Read these in parallel to build the dashboard:

### 1. Git State
```bash
git branch -a                    # All branches including build/* and ralph/*
git worktree list                # Active worktrees
git log --oneline -20            # Recent commits
git stash list                   # Stashed work
git status --porcelain           # Uncommitted changes
```

### 2. Roadmap Progress
Read `roadmap-progress.json` if it exists:
- Task statuses (pending, in_progress, completed, blocked)
- Dependency graph
- Scores from last review cycle

### 3. Plan Files
Search for `PLAN-*.md` and `PRD-*.md` files:
- Which plans are approved vs. in review
- Which steps are checked off vs. pending
- Any skipped steps with reasons

### 4. Environment Health
```bash
npm test 2>&1 | tail -5          # Test suite status (pass/fail count)
npx tsc --noEmit 2>&1 | tail -5  # Type errors
npm run build 2>&1 | tail -5     # Build status
```

### 5. Worktree Contents
For each active worktree in `.claude/worktrees/` or `../worktrees/`:
- Branch name
- Last commit timestamp and message
- Uncommitted changes count
- Whether PLAN-*.md exists and its completion percentage

## Output Format

```
╔══════════════════════════════════════════════════════════╗
║                   FACTORY STATUS                         ║
║                   [TIMESTAMP]                            ║
╠══════════════════════════════════════════════════════════╣

REPOSITORY: [repo-name] @ [branch] ([commit-sha])
  Build: ✓ passing | Tests: ✓ 47/47 | Types: ✓ clean

ACTIVE WORKTREES: [N]
  ┌─ build/t01-database-schema (3 commits, last: 2m ago)
  │  Steps: ████████░░ 8/10 complete
  │  Status: worker executing step 9
  │
  ├─ build/t02-api-endpoints (1 commit, last: 5m ago)
  │  Steps: ██░░░░░░░░ 2/10 complete
  │  Status: worker executing step 3
  │
  └─ build/t03-frontend (0 commits)
     Steps: blocked by t01
     Status: waiting

RECENT SCORES:
  t00-auth: architect 9.7 | executive 9.5 | critic 9.8 → MERGED
  t01-schema: architect 9.6 | executive 9.5 | critic pending

BLOCKERS: [N]
  ⚠ t03-frontend: blocked by t01 (dependency)
  ✗ t05-payments: critic rejected 2/5 (security: 7.2 — input validation missing)

BACKLOG: [N pending] | [M in_progress] | [K completed]

ENVIRONMENT:
  ✓ Supabase: connected
  ✓ Anthropic: connected
  ○ Stripe: not configured (optional)
```

## Behavior

- **No modifications.** This skill is read-only. It never changes files, branches, or state.
- **Fast.** No subagents. Read files and run git commands directly.
- **Honest.** If something is broken, show it in red. Don't hide problems.
- **Actionable.** For each blocker, suggest the next step to unblock it.

## When to Use

- After starting a `/build` to monitor progress
- After stepping away to see what happened
- Before starting new work to understand current state
- When something feels stuck to identify the blocker
