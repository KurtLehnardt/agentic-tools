---
name: survive-guard-overview
description: Identify and explain all five guards when wrapping a small-model worker loop
tags: [survive]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

I'm running a worker loop with Mistral 7B that keeps generating malformed JSON tool calls. The loop crashes on invalid syntax. How do I wrap this so it's survivable?
