---
name: release-infer-major-and-ask
description: Breaking commit implies major at 1.x or above; asks once before push
tags: [release]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

new release please. commits since v2.3.0: 'feat(api)!: drop v1 endpoints', 'fix: null check in parser', 'feat: add --json flag'. no bump type given
