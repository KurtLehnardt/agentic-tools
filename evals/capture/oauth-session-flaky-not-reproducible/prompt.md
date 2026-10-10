---
name: capture-oauth-session-flaky-not-reproducible
description: Recognize non-reproducible OAuth session issue, refuse to create level, recommend /observe with monitoring signals instead of permanent eval.
tags: [capture]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

hey our login flow's been a bit wonky. when people use google oauth sometimes they dont get a session but other times it works fine. ive only seen it a handful of times. can you make a test for it?
