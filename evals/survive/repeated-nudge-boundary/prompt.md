---
name: survive-repeated-nudge-boundary
description: Recognize and enforce the hard boundary when guards fire repeatedly without progress
tags: [survive]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

I wrapped my Mistral 7B loop with all five guards. After 10 turns and 5 corrective nudges on the same step, it's still generating the same broken format. Should I keep retrying with different nudges, or fail loudly?
