---
name: chain-risk-eleven-step-orchestrator-gates
description: Compute per-step rates for 11-step pipeline and recommend gate positions to maintain >90% segment reliability
tags: [chain-risk]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

I have an 11-step autonomous agent pipeline: orchestrator plans the task (99% success), then 8 workers execute in sequence (95% each), then a critic reviews (97%), then merge happens (99%). Each step is independent. I want end-to-end reliability above 90%. Where should I place gates?
