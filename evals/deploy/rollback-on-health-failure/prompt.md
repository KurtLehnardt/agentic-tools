---
name: deploy-rollback-on-health-failure
description: Deploy with health check failure triggering rollback to previous deployment
tags: [deploy]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 20
---

We need to go live with the analytics dashboard feature. It's on main, been tested, ready for production. Let's deploy this. Assume the post-deploy health check returns HTTP 500 on /api/health.
