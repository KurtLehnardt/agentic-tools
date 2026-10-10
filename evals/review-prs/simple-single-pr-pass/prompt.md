---
name: review-prs-simple-single-pr-pass
description: Single open PR scoring above 9.0 threshold with no conflicts, should be merged
tags: [review-prs]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

/review-prs — One open PR ready for merge review.

## Open PRs

```
PR #42 | fix/cache-invalidation | Author: alice@example.com | Base: main
```

## PR Details

PR #42 title: "Fix cache invalidation on user update"

Mergeable: true (no conflicts)

Additions: 23, Deletions: 8, Files changed: 2

### Diff for PR #42

```diff
--- a/src/cache.js
+++ b/src/cache.js
@@ -45,12 +45,18 @@ function updateUser(userId, data) {
   const user = getFromCache(userId);
   if (user) {
-    // stale cache entry, user will see old data
-    database.update(userId, data);
+    // Invalidate cache before update to prevent stale reads
+    invalidateCache(userId);
+    const result = database.update(userId, data);
+    recordMetric('user_update_cache_hit');
+    return result;
   }
   
-  database.update(userId, data);
+  // Cache miss: update and log
+  const result = database.update(userId, data);
+  recordMetric('user_update_cache_miss');
+  return result;
 }

--- a/tests/cache.test.js
+++ b/tests/cache.test.js
@@ -120,6 +120,12 @@ test('user update with cached data', () => {
   assert(getFromCache(userId) === null);
   assert(result.status === 'ok');
 });
+
+test('cache invalidation on concurrent updates', () => {
+  const userId = 'user-123';
+  updateUser(userId, { name: 'Updated' });
+  assert(getFromCache(userId) === null, 'cache should be invalidated');
+  assert(database.get(userId).name === 'Updated');
+});
 }
```

## Reviewer Assessment

Reviewer report for PR #42:
- Build safety: No breaking changes, maintains backward compatibility with existing cache API
- Merge conflicts: None — cleanly applies on top of main
- Code quality: Good — adds proper cache invalidation logic, fixes the stale cache bug, includes metrics
- Completeness: Delivers the promised cache fix with test coverage
- Redundancy: No overlap with other open PRs
- **Review Score: 9.3/10**
- VERDICT: MERGE

Review this PR. The skill should inventory it, review the score, and decide whether to merge it based on the 9.0+ threshold.
