---
name: delegate-size-mixed-task-list
description: Sizes a mixed task list with the model table and parallel worktree flow
tags: [delegate]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

delegate this: (1) rename the helper getUsr to getUser across utils.ts, (2) add pagination to the /orders endpoint plus tests, (3) redesign our auth token refresh so it works across the web app, the api and the worker, (4) run the linter and tell me the count. split it up, each in its own worktree, PRs reviewed and merged. dont ask me stuff, just go
