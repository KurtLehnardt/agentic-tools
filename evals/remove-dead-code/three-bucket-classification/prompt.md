---
name: remove-dead-code-three-bucket-classification
description: Correctly classify dead code into three buckets—delete, keep intentional, decide on unwired
tags: [remove-dead-code]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

Audit this codebase for dead code. It has a mix of truly dead, intentional-but-unused, and unwired features. Classify each correctly.

Main app (src/app.js):
```javascript
import axios from 'axios';
import { fetchUser } from './api.js';
import { createAdminPanel } from './admin.js';

// Entry point
async function start() {
  const user = await fetchUser(42);
  console.log(user);
}

start();
```

API module (src/api.js):
```javascript
import axios from 'axios';
import { validateUserData } from './validators.js';

export async function fetchUser(id) {
  const response = await axios.get(`/api/users/${id}`);
  return response.data;
}

// Only called in tests, not from production code
export function testHelper() {
  return { test: true };
}

// Never called anywhere, not even in tests
function orphanedHelper() {
  return { orphan: true };
}
```

Admin module (src/admin.js):
```javascript
// Complete feature: admin panel with auth, UI, and full implementation
// But it's never wired into the app—no route, no call from start()
export function createAdminPanel() {
  return {
    authenticate: (user) => user.role === 'admin',
    render: () => '<div id="admin">Admin Panel</div>',
    handleDelete: (itemId) => fetch(`/api/admin/delete/${itemId}`),
  };
}

// Internal helper for admin panel—only called by createAdminPanel
function _validateAdminRole(role) {
  return role === 'admin' || role === 'superadmin';
}
```

Test file (src/api.test.js):
```javascript
import { fetchUser, testHelper } from './api.js';

test('testHelper returns correct shape', () => {
  expect(testHelper()).toEqual({ test: true });
});
```

What's in bucket 1 (delete)? Bucket 2 (keep)? Bucket 3 (decide)?
