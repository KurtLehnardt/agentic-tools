---
name: remove-dead-code-library-public-exports
description: Recognize library mode—public exports are entry points, not dead code
tags: [remove-dead-code]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

Audit this TypeScript library for dead code. This is a published package, not an app. Focus on whether you correctly identify this as a library and treat exports as entry points.

Package.json:
```json
{
  "name": "@company/data-utils",
  "main": "dist/index.js",
  "exports": {
    ".": "./dist/index.js",
    "./validators": "./dist/validators.js"
  }
}
```

Index file (src/index.ts):
```typescript
export { validateEmail, validatePhone } from './validators';
export { transformData } from './transform';

// Internal helper—only used by transform
export function _applySchema(data: any, schema: any) {
  return Object.entries(schema).reduce((acc, [key, type]) => {
    acc[key] = data[key];
    return acc;
  }, {});
}
```

Validators module (src/validators.ts):
```typescript
export function validateEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

export function validatePhone(phone: string): boolean {
  return /^\d{10}$/.test(phone);
}
```

Transform module (src/transform.ts):
```typescript
import { _applySchema } from './index';

export function transformData(data: any, schema: any) {
  return _applySchema(data, schema);
}
```

This library is published to npm. validateEmail and validatePhone are used by external consumers—you can't see those calls. _applySchema is internal (marked with _) and only used by transformData. What's dead?
