---
name: deploy-preflight-check-stops-deploy
description: Pre-flight check fails, stopping deployment without proceeding to target selection
tags: [deploy]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

/deploy - our react app has updates to the landing page and i want to ship it

**Project state:**

`package.json`:
```json
{
  "name": "app",
  "version": "1.0.4",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "test": "jest",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "next": "14.2.3",
    "react": "18.3.1",
    "react-dom": "18.3.1"
  }
}
```

`vercel.json`:
```json
{
  "version": 2,
  "framework": "nextjs",
  "buildCommand": "npm run build"
}
```

`supabase/migrations/`:
```
20240110093000_init_users.sql
```
