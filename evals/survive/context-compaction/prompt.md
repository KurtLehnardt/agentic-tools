---
name: survive-context-compaction
description: Use context compaction to keep small-window models focused on long-running tasks
tags: [survive]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

Mistral 7B running a 15-step build task gets to step 8 then starts repeating steps 2-3 and losing the plan. Its context window is only 4K tokens. How do I use context compaction so it stays focused?
