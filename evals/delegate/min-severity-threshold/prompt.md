---
name: delegate-min-severity-threshold
description: Applies the --min severity threshold when deciding which findings to fix
tags: [delegate]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

/delegate --min high  critic findings on PR 12 are: [critical] SQL injection in search.ts, [high] missing auth check on /admin, [medium] N+1 query in list view, [low] inconsistent naming, [nit] trailing whitespace. what gets fixed
