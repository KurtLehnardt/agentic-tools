---
name: build-baseline-preexisting-failures
description: Capture baseline on origin/main, mark pre-existing failures, gate-check on delta to prevent false regressions
tags: [build]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 20
---

I want to add a new feature to my app. Main branch currently has 2 failing tests (test/auth.spec.ts line 42 timeout, test/perf.spec.ts line 80 flaky assertion). I've confirmed these are pre-existing. Here's my spec for the feature. Build the feature, but don't fail because of the existing failures.
