---
name: babysit-hard-limit-two-hour-exit
description: Detect 2-hour hard limit (24 ticks × 5 min), output warning, exit gracefully
tags: [babysit]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

I ran /loop 5m /babysit and it's been going for 2 hours. Check the workers one more time.
