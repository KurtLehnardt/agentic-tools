---
name: constitution-guard-handoff-user-injection
description: Phase 2 GUARD THE HANDOFF - detect injection in user-submitted data
tags: [constitution]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

setting up guardrails for multi-agent ops. core thing is safe deploys without exfiltrating secrets. got 3 agents and they need a constitution. users will submit forms, some might be bad actors. show me how you guard the handoff between intake and executor so someone cant inject 'ignore the no-exfil rule' through user data. include what happens when mutation is detected.
