---
name: review-prs-below-threshold-blocked
description: PR scoring below 9.0 threshold should be blocked and not merged
tags: [review-prs]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

/review-prs — One PR below merge threshold.

## Open PRs

```
PR #51 | feature/analytics-dashboard | Author: bob@example.com | Base: main
```

## PR Details

PR #51 title: "Add analytics dashboard component"

Mergeable: true (no conflicts)

Additions: 156, Deletions: 3, Files changed: 5

### Diff for PR #51 (truncated, showing key issue)

```diff
--- a/src/components/Dashboard.tsx
+++ b/src/components/Dashboard.tsx
@@ -0,0 +1,156 @@
+export function AnalyticsDashboard() {
+  // TODO: implement loading states
+  // TODO: implement error handling
+  const data = fetchAnalytics(); // hardcoded for now
+  const chartData = data.map(x => ({ value: x })); // simplified, loses labels
+  
+  return (
+    <div>
+      {chartData.map(d => (
+        <div key={d.value}>{d.value}</div>
+      ))}
+    </div>
+  );
+}
```

## Reviewer Assessment

Reviewer report for PR #51:
- Build safety: No immediate breakage, but missing error boundaries
- Merge conflicts: None — applies cleanly
- Code quality: ISSUES — hardcoded data fetch, incomplete error handling, no loading states (3 TODO comments), uses value as React key (anti-pattern)
- Completeness: Dashboard component exists but stub implementation, not ready for production
- Redundancy: No overlap detected
- **Review Score: 8.3/10**
- BLOCKING ISSUES: Hardcoded fetch call needs API integration, missing error handling required before merge, using primitive as React key is anti-pattern and will break with duplicate values
- VERDICT: BLOCK

Review this PR. The skill should identify that it scores below 9.0 and report blocking issues to the user, not merge it.
