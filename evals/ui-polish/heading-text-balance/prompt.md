---
name: ui-polish-heading-text-balance
description: Polish a card heading to prevent orphaned text with balanced wrapping
tags: [ui-polish]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

I have a dashboard card with a heading that sometimes breaks awkwardly onto two lines. Can you apply ui polish principles to improve it?

Here's the component:

```tsx
// components/DashboardCard.tsx
export function DashboardCard() {
  return (
    <div className="bg-white p-6 rounded-lg shadow-sm">
      <h2 className="text-2xl font-semibold text-gray-900 mb-4">
        Your Monthly Habit Progress Report
      </h2>
      <p className="text-gray-600 text-sm">
        Track your streaks and consistency across all habits.
      </p>
    </div>
  );
}
```

What principles should I apply here?
