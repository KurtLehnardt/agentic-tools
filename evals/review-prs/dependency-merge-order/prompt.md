---
name: review-prs-dependency-merge-order
description: Multiple PRs with dependencies must be merged in correct order
tags: [review-prs]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

/review-prs — Three open PRs with dependency relationship.

## Open PRs

```
PR #10 | fix/database-indexes    | Base: main      | Author: alice@example.com
PR #20 | feature/search-api       | Base: main      | Author: bob@example.com
PR #30 | feature/search-ui        | Base: feature/search-api | Author: carol@example.com
```

## PR Details

### PR #10
Title: "Add database indexes for performance"
Mergeable: true (no conflicts)
Additions: 12, Deletions: 5, Files changed: 1
Review Score: 9.2/10
VERDICT: MERGE

### PR #20
Title: "Implement search API endpoint"
Mergeable: true (no conflicts)
Base branch: main
Additions: 67, Deletions: 8, Files changed: 3
Depends on: PR #10 (uses database index from PR #10)
Review Score: 9.5/10
VERDICT: MERGE

### PR #30
Title: "Add search UI component"
Mergeable: true (no conflicts, assuming PR #20 is merged first)
Base branch: feature/search-api (the branch of PR #20)
Additions: 89, Deletions: 2, Files changed: 4
Depends on: PR #20 (uses search API from PR #20)
Review Score: 9.1/10
VERDICT: MERGE

## Dependency Graph

```
PR #10 (fix/database-indexes)
   ↓
PR #20 (feature/search-api, depends on PR #10's indexes)
   ↓
PR #30 (feature/search-ui, depends on PR #20's API)
```

## Inline Diffs (simplified)

### PR #10 diff
```diff
--- a/sql/migrations/create_indexes.sql
+++ b/sql/migrations/create_indexes.sql
@@ -0,0 +1,5 @@
+CREATE INDEX idx_users_email ON users(email);
+CREATE INDEX idx_posts_user_id ON posts(user_id);
+CREATE INDEX idx_posts_created_at ON posts(created_at);
```

### PR #20 diff
```diff
--- a/src/api/search.ts
+++ b/src/api/search.ts
@@ -0,0 +1,45 @@
+// Uses idx_users_email and idx_posts_user_id from PR #10
+export async function searchUsers(query: string) {
+  const results = db.query(
+    'SELECT * FROM users WHERE email LIKE $1',
+    [`%${query}%`]
+  );
+  return results;
+}
```

### PR #30 diff
```diff
--- a/src/components/SearchUI.tsx
+++ b/src/components/SearchUI.tsx
@@ -0,0 +1,52 @@
+// Uses searchUsers API from PR #20
+import { searchUsers } from '../api/search';
+
+export function SearchComponent() {
+  const [results, setResults] = useState([]);
+  
+  async function handleSearch(query: string) {
+    const data = await searchUsers(query);
+    setResults(data);
+  }
+  
+  return (
+    <div>
+      <input onChange={(e) => handleSearch(e.target.value)} />
+      {results.map(r => <div key={r.id}>{r.email}</div>)}
+    </div>
+  );
+}
```

Review these PRs. The skill should detect the dependency chain and merge in correct order: #10 first, then #20, then #30.
