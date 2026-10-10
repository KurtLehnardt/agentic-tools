---
name: architect-review
description: "Full architectural review of the codebase by a senior architect subagent. Finds and fixes CRITICAL/HIGH issues, reports MEDIUM/LOW. Trigger: architect review, architecture review, full review, code review."
user-invocable: true
---

# /architect-review — Full Architectural Review

You are an **orchestrator** that dispatches a senior software architect to review the entire codebase, then fixes any critical findings.

## Phase 1: REVIEW

Dispatch an **architect subagent** on an isolated worktree:

```
Subagent: Agent tool, subagent_type="general-purpose", isolation="worktree"
Prompt: You are a senior software architect performing a full architectural review.

        The project is at the repo root. Read key files to understand:
        - Project structure and framework
        - Database schema and migrations
        - API routes and server actions
        - Component architecture
        - Auth and security patterns
        - Shared code and monorepo structure (if applicable)

        Look for:
        1. Server/client component boundaries (correct 'use server'/'use client')
        2. Data fetching patterns (N+1 queries, missing parallelization)
        3. Auth flow completeness (middleware, route protection)
        4. Database issues (missing indexes, type mismatches with migrations)
        5. Duplicate code (types, utilities, shared logic)
        6. Dead files and unused imports
        7. Security issues (SQL injection, hardcoded secrets, missing auth checks)
        8. Error handling gaps
        9. Monorepo wiring (if applicable — shared packages, workspace deps)
        10. Build configuration (Vercel, CI/CD, lockfiles)

        Classify each finding as:
        - CRITICAL: Broken functionality, security vulnerability, build failure
        - HIGH: Best practice violation, performance issue, data integrity risk
        - MEDIUM: Code quality, consistency, maintainability
        - LOW: Style, minor improvement, documentation

        Fix all CRITICAL and HIGH issues. Make commits for each fix.
        Report MEDIUM and LOW findings without fixing.

        Output TASK_COMPLETE with: findings summary, commits made, unfixed items.
```

## Phase 2: CRITIC REVIEW

Dispatch a **critic subagent** to review the architect's fixes:

```
Subagent: Agent tool, subagent_type="general-purpose"
Prompt: Review the git diff of the architectural fixes.
        Run: `git diff main...<branch> --stat` and `git diff main...<branch>`

        Score each fix:
        - Does it actually resolve the identified issue?
        - Does it introduce new problems?
        - Is it the simplest correct fix?

        Overall score must be >= 9.6/10 to approve.
        If below threshold, list specific issues to fix.
```

**Gate:** If critic score < 9.6, dispatch the architect again with the critic's feedback. Max 3 iterations.

## Phase 3: MERGE

If critic approves:

1. Cherry-pick fixes to main (or merge the branch)
2. Push to origin
3. Verify Vercel deployment succeeds
4. Clean up worktrees

## Phase 4: REPORT

Output a structured report:

```markdown
## Architectural Review Results

### Fixed (CRITICAL/HIGH)
| # | Severity | Finding | Fix |
|---|----------|---------|-----|

### Unfixed (MEDIUM/LOW)
| # | Severity | Finding | Recommendation |
|---|----------|---------|----------------|

### Metrics
- Files reviewed: X
- Issues found: X (C critical, H high, M medium, L low)
- Issues fixed: X
- Critic score: X.X/10
```

## Known Patterns to Check

- **Migration numbering collisions** — multiple migrations with same number
- **pnpm-lock.yaml staleness** — lockfile doesn't match package.json
- **styled-jsx in TypeScript** — `<style jsx>` doesn't work, use `dangerouslySetInnerHTML`
- **Base UI type mismatches** — InputPrimitive vs native input
- **Turbopack config** — `turbopack: false` is invalid in next.config.ts
- **@skylite/shared imports** — verify the shared package is wired as a dependency
- **distDir in monorepo** — Next.js output must be at the path Vercel expects
