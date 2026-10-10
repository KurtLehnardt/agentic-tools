---
name: babysit-delete-stale-nudge-recovered-worker
description: Delete stale NUDGE.md when worker recovers; do not re-nudge; assess healthy workers
tags: [babysit]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

babysit check: build/t01-auth-middleware has all 4 assigned steps completed (feat(t01): step 1-4 commits all present, 11 minutes ago). Last babysit tick wrote NUDGE.md to t01 for SLOW progress (was on step 2 of 4, 18 mins elapsed). build/t02-rate-limiter is in progress (2/3 steps, last commit 7 mins ago, Small task, all files in scope). A NUDGE.md exists for t01 from the previous check.
