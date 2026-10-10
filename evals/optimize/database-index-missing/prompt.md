---
name: optimize-database-index-missing
description: Add indexes for frequently filtered or joined columns
tags: [optimize]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

I'm seeing slow queries on my users table. Here's my current schema (created in an earlier migration):

```sql
-- supabase/migrations/0001_create_users.sql
CREATE TABLE users (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  email TEXT NOT NULL UNIQUE,
  name TEXT,
  role TEXT NOT NULL DEFAULT 'user',
  workspace_id BIGINT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE tasks (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  title TEXT NOT NULL,
  user_id BIGINT NOT NULL REFERENCES users(id),
  workspace_id BIGINT NOT NULL REFERENCES workspaces(id),
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT NOW()
);
```

My app frequently queries:
- `SELECT * FROM users WHERE workspace_id = ?` (admin dashboard loads all users in a workspace)
- `SELECT * FROM tasks WHERE status = 'pending' AND workspace_id = ?` (task filters)
- `SELECT * FROM users WHERE role = 'admin'` (finding admins)
- JOINs: `tasks JOIN users ON tasks.user_id = users.id` (loading tasks with assignee names)

These queries are slow because the columns aren't indexed. Create a migration that adds the necessary indexes.
