---
name: deploy-staging-with-migrations
description: Deploy to staging with database migrations, verifying pre-flight and health checks
tags: [deploy]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

I've just merged a feature branch that adds a new user profile page to our Next.js app on Vercel. The branch includes a database migration that adds a profiles table. Can you deploy this to staging so our QA team can test it?
