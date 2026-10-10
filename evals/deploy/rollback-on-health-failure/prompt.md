---
name: deploy-rollback-on-health-failure
description: Deploy with health check failure triggering rollback to previous deployment
tags: [deploy]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 20
---

We need to go live with the analytics dashboard feature. It's on main, been tested, ready for production. Let's deploy this. Assume the post-deploy health check returns HTTP 500 on /api/health.

**Project state:**

`package.json`:
```json
{
  "name": "app",
  "version": "1.9.0",
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
20240330110000_add_analytics_events_table.sql   <- already applied in staging
```
