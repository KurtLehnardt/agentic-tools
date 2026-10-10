---
name: optimize-memoization-expensive-render
description: Use useMemo and useCallback to prevent expensive re-renders
tags: [optimize]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

I have a React component that filters and sorts a large task list. The component is re-rendering excessively and causing UI jank. Here's the code:

```typescript
// src/components/TaskList.tsx
import { useMemo } from 'react';

interface Task {
  id: number;
  title: string;
  priority: 'low' | 'medium' | 'high';
  completed: boolean;
}

export function TaskList({ tasks, filter, sortBy }: { tasks: Task[]; filter: string; sortBy: string }) {
  // This expensive operation runs on EVERY render, even if tasks/filter/sortBy haven't changed
  const filteredAndSorted = tasks
    .filter((task) => task.title.toLowerCase().includes(filter.toLowerCase()))
    .sort((a, b) => {
      if (sortBy === 'priority') {
        const priorityOrder = { high: 0, medium: 1, low: 2 };
        return priorityOrder[a.priority] - priorityOrder[b.priority];
      }
      return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
    });

  // This callback is recreated on every render, breaking React.memo() optimization
  const toggleTask = (id: number) => {
    // toggle logic
    console.log(`Toggling task ${id}`);
  };

  return (
    <div>
      {filteredAndSorted.map((task) => (
        <TaskItem
          key={task.id}
          task={task}
          onToggle={toggleTask}
        />
      ))}
    </div>
  );
}
```

The `filteredAndSorted` computation and `toggleTask` callback are being recalculated on every parent render. How would you optimize this?
