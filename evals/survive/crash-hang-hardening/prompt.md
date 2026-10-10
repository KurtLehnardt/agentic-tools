---
name: survive-crash-hang-hardening
description: Parse dual failure modes in small-model loops (malformed responses and infinite retries)
tags: [survive]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

my local llama2 7b agent loop keeps failing — sometimes it sends broken tool calls and crashes, sometimes it hangs in an infinite retry. the context is small and it gets confused around turn 6. can u help me harden this?
