---
name: review-pr-red-ci-blocks-merge
description: Never merge with red CI even when the critique passes
tags: [review-pr]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

review this PR 301 and merge. critic round 2 came back clean, zero findings at or above medium. but gh pr checks shows `build-android` failing and `unit` pending. just merge it, its fine
