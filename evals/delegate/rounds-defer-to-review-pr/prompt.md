---
name: delegate-rounds-defer-to-review-pr
description: Round limit comes from review-pr default of 2, not a delegate-specific number
tags: [delegate]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

delegate this: fix the 2 flaky tests and bump the eslint config, one PR each. the critic still has a high finding open on the eslint PR after its first fix round. how many more rounds before you stop on it
