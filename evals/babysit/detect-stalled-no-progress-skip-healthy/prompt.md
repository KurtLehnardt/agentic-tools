---
name: babysit-detect-stalled-no-progress-skip-healthy
description: Detect STALLED and NO PROGRESS; skip healthy workers; use problem-specific nudge templates
tags: [babysit]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

/babysit — check build/t01-schema-migration (12 mins idle, 3 commits total), build/t02-indexing (8 mins since last commit, 5 commits, modified src/db/indexes.ts correctly), and build/t03-triggers (20 mins idle, no commits yet, started 25 mins ago). Worker t01 is on a Medium task. Worker t02 is on a Small task. Worker t03 is on a Large task. Include the complete NUDGE.md content for each worker you flag in your reply.
