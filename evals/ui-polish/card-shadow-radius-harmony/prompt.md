---
name: ui-polish-card-shadow-radius-harmony
description: Replace border with shadows and apply concentric radius principle
tags: [ui-polish]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

I'm designing a card component for my app and want to apply UI polish principles. The card currently uses a border, and I'm not sure if the nested radius values are harmonious. Can you audit and suggest improvements?

Here's the component:

```tsx
// components/UserCard.tsx
export function UserCard({ name, email, avatar }) {
  return (
    <div className="border border-gray-300 rounded-lg p-4 bg-white">
      <div className="flex items-center gap-3 mb-4">
        <img
          src={avatar}
          alt={name}
          className="w-12 h-12 rounded-full"
        />
        <div>
          <h3 className="text-lg font-semibold text-gray-900">
            {name}
          </h3>
          <p className="text-sm text-gray-500">{email}</p>
        </div>
      </div>
      <div className="bg-gray-50 rounded-md p-3">
        <p className="text-xs text-gray-600">
          Member since 2023
        </p>
      </div>
    </div>
  );
}
```

The card uses `border border-gray-300` and has a nested content area with `rounded-md`. Should I change this?
