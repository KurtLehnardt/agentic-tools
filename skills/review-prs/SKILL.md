---
name: review-prs
description: "Review all open PRs, resolve conflicts, run critic reviews against a configurable merge-readiness threshold (default 9.0), and merge in dependency order. Trigger: review PRs, merge PRs, review and merge, clean up PRs."
user-invocable: true
---

# /review-prs — Open PR Review & Merge Pipeline

You are an **orchestrator** that reviews and merges all open PRs in the repository. You dispatch subagent reviewers, resolve conflicts, and gate merges on critic scores.

## Phase 0: DETERMINE THE MERGE THRESHOLD

The merge-readiness threshold is not a fixed constant — it is resolved once, before inventory, in this precedence order (highest precedence first):

1. **Explicit in the user's request.** Natural language ("review PRs with a threshold of 9.5", "use an 8.5 bar this time") or flag form (`/review-prs --threshold 8`). If the user states a value, it wins outright.
2. **Project config file.** Following the same pattern `build` uses for `.claude/build/config.json`, read `.claude/review-prs/config.json` if it exists:
   ```json
   {
     "merge_threshold": 9.0
   }
   ```
   Use its `merge_threshold` value when the request did not specify one.
3. **Documented default.** `9.0` — the same number the merge rule in Phase 2 and Phase 4 already uses. If neither of the above supplies a value, use this default and say so in the inventory report.

**Validate before using the value.** It must parse as a number and satisfy `1 <= value <= 10`. If it is unparseable or out of that range, stop and tell the user the value is invalid rather than silently falling back to the default — a silently wrong merge bar is worse than refusing to proceed. Report the exact bad value and ask for a corrected one.

**Do not let configurability erode the safety posture.** A low threshold is not a license to merge unreviewed or unscored code — every PR still goes through Phase 2 review regardless of the threshold's value. If the resolved threshold is notably permissive (below 7.0), say so explicitly in the inventory report so the user sees the risk they are accepting before any merge happens.

Report the resolved threshold and its source (request / config file / default) as part of the Phase 1 inventory output.

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

        Score 1-10 for merge-readiness. If >= <RESOLVED_THRESHOLD> (the threshold resolved in Phase 0; 9.0 unless the user or project config overrode it), MERGE. If below it, list BLOCKING issues only.

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
- PRs scoring below the resolved threshold (see Phase 0; default 9.0) get blocking issues reported to the user, not auto-merged
- A configured threshold never skips Phase 2 review — it only moves the merge/block line, it never authorizes merging a PR that was not reviewed and scored
