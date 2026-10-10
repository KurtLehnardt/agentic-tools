---
name: review-prs-invalid-threshold-rejected
description: Unparseable threshold value is rejected with an error instead of silently defaulting
tags: [review-prs]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

/review-prs --threshold banana — One open PR, but the supplied threshold is garbage.

## Open PRs

```
PR #88 | chore/update-deps | Author: fay@example.com | Base: main
```

## PR Details

PR #88 title: "Bump lodash and eslint versions"

Mergeable: true (no conflicts)

Additions: 14, Deletions: 14, Files changed: 2

### Diff for PR #88

```diff
--- a/package.json
+++ b/package.json
@@ -12,8 +12,8 @@
-    "lodash": "^4.17.19",
-    "eslint": "^7.32.0"
+    "lodash": "^4.17.21",
+    "eslint": "^8.57.0"
```

## Reviewer Assessment

Reviewer report for PR #88:
- Build safety: Patch/minor bumps only, low risk
- Merge conflicts: None — applies cleanly
- Code quality: N/A — dependency bump only
- Completeness: Delivers the bump described in the title
- Redundancy: No overlap with other open PRs
- **Review Score: 9.4/10**
- VERDICT: MERGE

The user invoked this with `--threshold banana`, which is not a number. Review this PR. The skill should notice the threshold value fails validation (unparseable, not a number between 1 and 10), stop, and tell the user the value is invalid rather than silently proceeding with the 9.0 default or merging PR #88.
