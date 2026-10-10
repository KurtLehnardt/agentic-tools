---
name: chain-risk-forty-step-gate-adequacy
description: Verify existing gate placement and recommend additional gates to keep segments above 90%
tags: [chain-risk]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

/chain-risk — we already have gates: checkpoint after step 10 (validates schema, 98% pass), checkpoint after step 25 (reviewer approval, 99% pass), final merge gate (99%). steps 1-10 average 96%, steps 11-25 average 95%, steps 26-40 average 94%. do these gates place correctly? should we add more?
