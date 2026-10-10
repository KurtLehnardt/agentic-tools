---
name: build-auth-conflict-resolution
description: Detect and escalate spec conflicts during build, amend ledger with approval, resume build
tags: [build]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 20
---

Build a user authentication subsystem. Spec is at spec.md: passwords expire every 90 days (R-001), refresh tokens revoke on logout (R-002), IP change forces re-auth (R-003), rate limit login to 5/min (R-004). Start the build now.
