---
name: architect-review-monorepo-workspace
description: Monorepo with shared packages and workspace dependencies
tags: [architect-review]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

Review this monorepo structure. We're using pnpm workspaces to share code across multiple Next.js apps. Check if the wiring is correct and if there are any issues with package dependencies or migrations.

**Root package.json:**
```json
{
  "name": "monorepo",
  "private": true,
  "workspaces": [
    "apps/web",
    "apps/admin",
    "packages/shared",
    "packages/db"
  ],
  "devDependencies": {
    "typescript": "^5.2.0",
    "eslint": "^8.50.0"
  }
}
```

**packages/shared/package.json:**
```json
{
  "name": "@monorepo/shared",
  "version": "1.0.0",
  "main": "dist/index.js",
  "exports": {
    ".": "./dist/index.js",
    "./types": "./dist/types.js"
  },
  "dependencies": {
    "zod": "^3.22.0"
  }
}
```

**packages/shared/src/index.ts:**
```typescript
export const API_BASE_URL = 'https://api.example.com';
export const APP_NAME = 'Platform';

export function formatDate(date: Date): string {
  return new Intl.DateTimeFormat('en-US').format(date);
}

export interface User {
  id: string;
  email: string;
  role: 'admin' | 'user';
}
```

**packages/db/package.json:**
```json
{
  "name": "@monorepo/db",
  "version": "1.0.0",
  "main": "dist/index.js",
  "dependencies": {
    "postgres": "^3.3.0"
  }
}
```

**packages/db/src/index.ts:**
```typescript
import { Pool } from 'postgres';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

export async function query(text: string, params?: any[]) {
  return pool.query(text, params);
}

export async function migrate(version: number) {
  const migrations = [
    { id: 1, name: '001_init_schema.sql' },
    { id: 1, name: '002_add_users.sql' },  // CRITICAL: duplicate migration ID
    { id: 3, name: '003_add_products.sql' },
    { id: 4, name: '004_add_orders.sql' }
  ];

  const targetMigration = migrations.find(m => m.id === version);
  if (targetMigration) {
    // Run migration
  }
}
```

**apps/web/package.json:**
```json
{
  "name": "web",
  "version": "0.1.0",
  "private": true,
  "dependencies": {
    "next": "^14.0.0",
    "react": "^18.2.0",
    "@monorepo/shared": "*",
    "@monorepo/db": "*"
  },
  "devDependencies": {
    "typescript": "^5.2.0"
  }
}
```

**apps/web/app/page.tsx:**
```typescript
import { API_BASE_URL, APP_NAME, User } from '@monorepo/shared';
import { query } from '@monorepo/db';

export default async function Home() {
  const users = await query('SELECT * FROM users LIMIT 10');

  return (
    <main>
      <h1>{APP_NAME}</h1>
      <p>API: {API_BASE_URL}</p>
      <div>
        {users.map((user: User) => (
          <div key={user.id}>{user.email}</div>
        ))}
      </div>
    </main>
  );
}
```

**apps/admin/package.json:**
```json
{
  "name": "admin",
  "version": "0.1.0",
  "private": true,
  "dependencies": {
    "next": "^14.0.0",
    "react": "^18.2.0",
    "@monorepo/shared": "*",
    "@monorepo/db": "*"
  }
}
```

**apps/admin/app/page.tsx:**
```typescript
import { APP_NAME, User } from '@monorepo/shared';
import { query } from '@monorepo/db';

export default async function AdminPage() {
  const users = await query('SELECT * FROM users');

  return (
    <main>
      <h1>Admin - {APP_NAME}</h1>
      <div>
        {users.map((user: User) => (
          <div key={user.id}>{user.email} ({user.role})</div>
        ))}
      </div>
    </main>
  );
}
```

**pnpm-lock.yaml (excerpt):**
```
lockfileVersion: 5.4
...
packages:
  '@monorepo/db': ...
  '@monorepo/shared': ...
dependencies:
  '@monorepo/db': link: packages/db
  '@monorepo/shared': link: packages/shared
```

Review this monorepo. Check the workspace wiring, package dependencies, and any structural issues.
