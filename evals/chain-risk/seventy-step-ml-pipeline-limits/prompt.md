---
name: chain-risk-seventy-step-ml-pipeline-limits
description: Determine whether a 70-step ML pipeline can reach 99% reliability with gating alone or if redesign is required
tags: [chain-risk]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

I have a 70-step ML training + inference loop: data prep (12 steps, 0.96 each), training (25 steps, 0.93 each), evaluation (15 steps, 0.95 each), serving (18 steps, 0.91 each). End-to-end is currently ~0.85% even with intended gates. I want 99% reliability. Can we gate this or should we redesign?
