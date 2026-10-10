---
name: observe-safety-anomaly-detection
description: Wire observability for safety anomalies and feed them to downstream containment and integrity guards
tags: [observe]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

We detected a model call that tried to make an unauthorized AWS API call — it's non-reproducible, only happened once in production. We need observability to catch this again and prevent it from happening. The agent should also block such anomalies. How do I wire this?
