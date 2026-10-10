---
name: optimize-query-parallelization
description: Convert sequential DB awaits to Promise.all for parallel execution
tags: [optimize]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

I need to optimize a performance issue in my Next.js app. A data-fetching function is making sequential database calls that block each other. Here's the current code:

```typescript
// src/app/dashboard/page.tsx
import { db } from '@/lib/db';

export default async function DashboardPage() {
  // These queries run sequentially — each waits for the previous to finish
  const events = await db.select('events').where({ userId: 123 });
  const members = await db.select('members').where({ userId: 123 });
  const taskCount = await db.select('tasks').where({ userId: 123 }).count();
  const completedCount = await db.select('tasks').where({ userId: 123, completed: true }).count();

  return (
    <div>
      <h1>Dashboard</h1>
      <p>Events: {events.length}</p>
      <p>Members: {members.length}</p>
      <p>Tasks: {taskCount}, Completed: {completedCount}</p>
    </div>
  );
}
```

Each query takes ~100-200ms, so total load time is ~400-800ms. They don't depend on each other — they can run in parallel. How would you optimize this? Show me the change you'd make.
