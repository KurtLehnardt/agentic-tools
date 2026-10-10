---
name: ui-polish-restrain-well-designed-card
description: Recognize when a component is already well-polished and avoid over-engineering
tags: [ui-polish]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

I want to make sure my profile card is as polished as possible. Can you audit it against ui polish principles and suggest improvements?

Here's the component:

```tsx
// components/ProfileCard.tsx
export function ProfileCard({ user }) {
  return (
    <div
      className="bg-white rounded-lg p-6 shadow-sm"
      style={{
        boxShadow: '0px 0px 0px 1px rgba(0, 0, 0, 0.06), 0px 1px 2px -1px rgba(0, 0, 0, 0.06), 0px 2px 4px 0px rgba(0, 0, 0, 0.04)'
      }}
    >
      <div className="flex items-center gap-4 mb-4">
        <img
          src={user.avatar}
          alt={user.name}
          className="w-16 h-16 rounded-full"
          style={{
            outline: '1px solid rgba(0, 0, 0, 0.1)',
            outlineOffset: '-1px'
          }}
        />
        <div>
          <h2 className="text-lg font-semibold text-gray-900" style={{ textWrap: 'balance' }}>
            {user.name}
          </h2>
          <p className="text-sm text-gray-500">{user.role}</p>
        </div>
      </div>
      <p className="text-sm text-gray-700 leading-relaxed">
        {user.bio}
      </p>
    </div>
  );
}
```

I've already applied some techniques I found online. Is there anything else I should add to make it more polished?
