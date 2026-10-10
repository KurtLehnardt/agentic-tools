---
name: remove-dead-code-simple-unused-import
description: Identify basic unused imports and orphaned functions as truly dead code
tags: [remove-dead-code]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

I have a small JavaScript module with some unused imports and functions. Audit it for dead code and report what's dead, what's intentional, and what's uncertain.

Here's the code:

```javascript
// src/utils.js
import { readFileSync, writeFileSync } from 'fs';
import { parse as parseYaml } from 'yaml';
import axios from 'axios';

export function loadConfig(filePath) {
  const content = readFileSync(filePath, 'utf8');
  return JSON.parse(content);
}

function fetchUserData(userId) {
  // This function exists but is never called from an entry point
  return axios.get(`/api/users/${userId}`);
}

function validateEmail(email) {
  // This helper is defined but never exported or called
  return email.includes('@');
}

export function processData(data) {
  // Only uses readFileSync and JSON, not writeFileSync or parseYaml
  const processed = readFileSync('/tmp/data.json', 'utf8');
  return JSON.parse(processed);
}
```

Entry point (src/index.js):
```javascript
import { loadConfig, processData } from './utils.js';

export const config = loadConfig('./config.json');
export const result = processData(config);
```

What's dead? What should stay? What's uncertain?
