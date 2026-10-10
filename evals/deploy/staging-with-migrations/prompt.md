---
name: deploy-staging-with-migrations
description: Deploy to staging with database migrations, verifying pre-flight and health checks
tags: [deploy]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

I've just merged a feature branch that adds a new user profile page to our Next.js app on Vercel. The branch includes a database migration that adds a profiles table. Can you deploy this to staging so our QA team can test it?

**Project state:**

`package.json`:
```json
{
  "name": "app",
  "version": "1.4.2",
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
20240221141500_add_profiles_table.sql   <- new in this branch, not yet applied to staging
```
