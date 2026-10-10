---
name: observe-phase-one-gate
description: Reject blanket 15-LLM instrumentation request and redirect to Phase 1 single critical use case
tags: [observe]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

/observe My autonomous agent system has 15 different LLM calls: planning (claude), routing (haiku), execution (opus), validation (claude), and reporting (gpt-4o). I want comprehensive monitoring across all of them — P95 latency, cost, errors, and quality scores. Set this up.
