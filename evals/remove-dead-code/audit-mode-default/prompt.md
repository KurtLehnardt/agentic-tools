---
name: remove-dead-code-audit-mode-default
description: Default to audit mode—report dead code but do not delete without explicit permission
tags: [remove-dead-code]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

I want you to find dead code in my module. Here's the code:

```javascript
// src/helpers.js
export function usedFunction(x) {
  return x * 2;
}

export function unusedFunction(y) {
  return y + 1;
}

export function anotherUnused(z) {
  return z;
}
```

Entry point (src/app.js):
```javascript
import { usedFunction } from './helpers.js';

console.log(usedFunction(5));
```

Find the dead code and tell me what to do about it. I did NOT say "remove dead code" or "delete"—I just said "find it."
