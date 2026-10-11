---
name: review-pr-then-action-and-merge-method
description: Parses --then and detects merge convention, shows full plan
tags: [review-pr]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

critique the PR, fix any findings that aren't nitpick, and merge. then rebuild the android app. the repo only ever squash merges
