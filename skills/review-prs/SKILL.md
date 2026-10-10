---
name: review-prs
description: "Review all open PRs, resolve conflicts, run critic reviews at 9.6+ threshold, and merge in dependency order. Trigger: review PRs, merge PRs, review and merge, clean up PRs."
user-invocable: true
---

# /review-prs — Open PR Review & Merge Pipeline

You are an **orchestrator** that reviews and merges all open PRs in the repository. You dispatch subagent reviewers, resolve conflicts, and gate merges on critic scores.

## Phase 1: INVENTORY

1. Run `gh pr list --state open --json number,title,headRefName,baseRefName,createdAt` to list all open PRs.
2. For each PR, check `gh pr view <number> --json mergeable,additions,deletions,changedFiles`.
3. Determine merge order based on dependencies (PRs targeting other PR branches must wait).
4. Report the inventory to the user.

## Phase 2: PARALLEL REVIEW

For each open PR, dispatch a **reviewer subagent** in parallel:

```
Subagent: Agent tool, subagent_type="general-purpose"
Prompt: You are a senior engineer reviewing PR #<NUMBER> for the <PROJECT> project.

        Run: `gh pr diff <NUMBER> --patch 2>&1 | head -3000`
        Also check: `gh pr view <NUMBER> --json mergeable`

        Review for:
        1. Build safety — will this break existing functionality?
        2. Merge conflicts — is it mergeable?
        3. Code quality — obvious issues?
        4. Completeness — does it deliver what the title promises?
        5. Redundancy — does it overlap with other open PRs?

        Score 1-10 for merge-readiness. If >= 9.0, MERGE. If < 9.0, list BLOCKING issues only.

        Return: VERDICT: MERGE or BLOCK, SCORE: X.X/10, BLOCKING_ISSUES: [...], NOTES: [...]
```

## Phase 3: CONFLICT RESOLUTION

For PRs marked MERGE but with conflicts:

1. Create a worktree: `git worktree add .claude/worktrees/pr-<number> origin/<branch>`
2. Merge main into the branch: `git merge origin/main --no-edit`
3. Resolve conflicts:
   - For file-level conflicts: prefer main's version for shared infrastructure files (package.json, lockfiles, config)
   - For feature-specific files: prefer the PR branch's version
   - For both-modified content: dispatch a subagent to intelligently merge
4. Commit the resolution and push
5. Verify `gh pr view <number> --json mergeable` shows MERGEABLE

## Phase 4: MERGE SEQUENCE

Merge PRs in dependency order:

1. PRs targeting main with no dependencies → merge first
2. PRs targeting other PRs → update base to main after dependency merges, then merge
3. After each merge:
   - Run `gh pr view <number> --json state` to verify MERGED
   - Check if any remaining PRs need their base updated
4. Close any PRs that are redundant (content already in main via another PR)

## Phase 5: VERIFICATION

After all PRs are merged:

1. `git pull origin main` to update local
2. Check Vercel: `npx vercel ls 2>&1 | grep "●" | head -3`
3. If build fails, diagnose and fix (dispatch worker subagent on worktree)
4. Report final status

## Rules

- **Never force-push** to main
- **Always use worktrees** for conflict resolution
- **Close redundant PRs** with an explanatory comment
- **Fix lockfile conflicts** by regenerating: `pnpm install --no-frozen-lockfile`
- **Check migration numbering** — renumber if collisions exist
- **Verify Vercel deployment** after merges complete
- PRs scoring below 9.0 get blocking issues reported to the user, not auto-merged
