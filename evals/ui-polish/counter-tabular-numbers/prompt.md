---
name: ui-polish-counter-tabular-numbers
description: Apply tabular-nums to prevent jittery dynamic number updates
tags: [ui-polish]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

I built a habit counter that increments throughout the day. When the number updates, it feels slightly janky because the digits shift width. Can you audit this with ui polish principles?

Here's the component:

```tsx
// components/HabitCounter.tsx
import { useState, useEffect } from 'react';

export function HabitCounter({ habitId }) {
  const [count, setCount] = useState(0);

  useEffect(() => {
    // Simulated counter that increments
    const timer = setInterval(() => {
      setCount(c => c + 1);
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  return (
    <div className="p-4 bg-white rounded-lg">
      <h3 className="text-sm font-medium text-gray-600 mb-2">
        Daily Habit Count
      </h3>
      <p className="text-4xl font-bold text-blue-600 font-mono">
        {String(count).padStart(3, '0')}
      </p>
    </div>
  );
}
```

The counter looks a bit twitchy when numbers update. Any suggestions?
