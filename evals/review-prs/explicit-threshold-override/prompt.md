---
name: review-prs-explicit-threshold-override
description: Explicit threshold in the user request overrides the 9.0 default and the reviewer's assumed bar
tags: [review-prs]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

/review-prs --threshold 9.5 — One open PR, explicit threshold overrides the 9.0 default.

## Open PRs

```
PR #77 | feature/rate-limiter | Author: dana@example.com | Base: main
```

## PR Details

PR #77 title: "Add per-user rate limiting middleware"

Mergeable: true (no conflicts)

Additions: 41, Deletions: 6, Files changed: 2

### Diff for PR #77

```diff
--- a/src/middleware/rateLimit.js
+++ b/src/middleware/rateLimit.js
@@ -1,8 +1,20 @@
+const buckets = new Map();
+
+function rateLimit(req, res, next) {
+  const key = req.user?.id || req.ip;
+  const bucket = buckets.get(key) || { count: 0, resetAt: Date.now() + 60000 };
+  if (bucket.count >= 100) {
+    return res.status(429).send('Too many requests');
+  }
+  bucket.count += 1;
+  buckets.set(key, bucket);
+  next();
+}
+
+module.exports = { rateLimit };
```

## Reviewer Assessment

Reviewer report for PR #77:
- Build safety: No breaking changes, additive middleware only
- Merge conflicts: None — applies cleanly
- Code quality: Good — simple bucket algorithm, no persistence across restarts (acceptable for v1)
- Completeness: Delivers rate limiting as described, no tests included
- Redundancy: No overlap with other open PRs
- **Review Score: 9.3/10**
- VERDICT: MERGE (reviewer applied the standard 9.0 bar)

The user invoked this with an explicit threshold of 9.5 in the request itself. Review this PR. The skill should resolve the threshold from the explicit request (9.5), not the 9.0 default the reviewer assumed, and re-apply that threshold: since 9.3 < 9.5, the PR does not clear the user's explicit bar even though the reviewer's own note says it would clear the standard 9.0 one.
