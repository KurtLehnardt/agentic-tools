---
name: route-escalation-cap-exceeded
description: Recognize escalation cap and escalate to human
tags: [route]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

We escalated a task up the ladder: haiku failed → escalated to sonnet, sonnet failed → escalated to opus. Now opus also fails the gate. We've done 3 escalations (the default cap). What do we do? Can we escalate to a custom model or try again?
