---
name: optimize-n-plus-one-queries
description: Eliminate N+1 query pattern by batch-fetching related data
tags: [optimize]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

I have a performance issue in my task list view. Here's the code that loads tasks and their associated member names:

```typescript
// src/app/tasks/page.tsx
import { db } from '@/lib/db';

export default async function TasksPage() {
  const tasks = await db.select('tasks').where({ projectId: 456 });

  // For each task, look up the assigned member's name — this is N+1!
  const enrichedTasks = await Promise.all(
    tasks.map(async (task) => {
      const member = await db.select('members').where({ id: task.assignedMemberId }).first();
      return {
        ...task,
        memberName: member?.name || 'Unassigned',
      };
    })
  );

  return (
    <div>
      <h1>Tasks</h1>
      {enrichedTasks.map((task) => (
        <div key={task.id}>
          <p>{task.title} — assigned to {task.memberName}</p>
        </div>
      ))}
    </div>
  );
}
```

With 50 tasks, this makes 1 query to load tasks + 50 queries to load members = 51 total. This is slow. How would you fix the N+1 pattern?
