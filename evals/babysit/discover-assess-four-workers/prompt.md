---
name: babysit-discover-assess-four-workers
description: Discover and assess 4 build worktrees, detect problems, write NUDGE.md atomically, tabular console report
tags: [babysit]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

I have 4 workers running on build/t01-database, build/t02-api, build/t03-auth, and build/t04-frontend branches. Can you check on them? Some have been running for a while.
