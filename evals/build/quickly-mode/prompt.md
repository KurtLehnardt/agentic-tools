---
name: build-quickly-mode
description: /build --quickly runs the low-token pipeline with a single final opus PR review
tags: [build]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 20
---

/build --quickly  add a small rate limiter to my express api. spec is in spec.md: 100 req/min per ip, 429 with retry-after header, configurable via env. i have npm test and npm run build. keep it cheap, just give me a pr.
