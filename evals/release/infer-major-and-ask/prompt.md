---
name: release-infer-major-and-ask
description: Breaking commit implies major; asks once before push
tags: [release]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

new release please. commits since v0.9.4: 'feat(api)!: drop v1 endpoints', 'fix: null check in parser', 'feat: add --json flag'. no bump type given
