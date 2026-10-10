---
name: review-prs-config-threshold-used
description: Project config file merge_threshold is used when the request itself names no threshold
tags: [review-prs]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

/review-prs — One open PR. The request itself names no threshold, but the project config file sets one.

## Project Config

`.claude/review-prs/config.json` exists in this repository with the following contents:

```json
{
  "merge_threshold": 8.5
}
```

## Open PRs

```
PR #63 | fix/pagination-offset | Author: eli@example.com | Base: main
```

## PR Details

PR #63 title: "Fix off-by-one error in pagination offset"

Mergeable: true (no conflicts)

Additions: 9, Deletions: 4, Files changed: 1

### Diff for PR #63

```diff
--- a/src/api/paginate.js
+++ b/src/api/paginate.js
@@ -3,7 +3,7 @@ function paginate(items, page, pageSize) {
-  const start = page * pageSize;
+  const start = (page - 1) * pageSize;
   const end = start + pageSize;
   return items.slice(start, end);
 }
```

## Reviewer Assessment

Reviewer report for PR #63:
- Build safety: No breaking changes, fixes a real bug
- Merge conflicts: None — applies cleanly
- Code quality: Minor — single-line fix, no test added for the off-by-one case
- Completeness: Delivers the fix described in the title
- Redundancy: No overlap with other open PRs
- **Review Score: 8.7/10**
- VERDICT: BLOCK under a 9.0 bar, MERGE under the project's configured 8.5 bar

Review this PR. The request does not mention any threshold. The skill should pick up the project config file's merge_threshold of 8.5 (since the request is silent and config.json exists), not fall back to the 9.0 documented default, and conclude PR #63 clears 8.5.
