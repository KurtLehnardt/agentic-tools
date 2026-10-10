---
name: chain-risk-fifty-step-multi-segment-correlation
description: Compute multi-segment p^n with correlated failure risk and determine if gating alone is viable
tags: [chain-risk]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

my pipeline is 50 steps: 5 data validation, 10 model inference calls, 20 result aggregation, 15 formatting steps. success rates: validation 98%, inference 92%, aggregation 95%, formatting 94%. but inference failures might poison aggregation (correlated). target reliability 95%. where do i add gates? is this even gatable?
