---
name: test-auth-depth-gaps
description: Deepen test coverage for mission-critical auth module with shallow existing tests
tags: [test]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

I have an auth module with some existing tests covering login and signup, but they only test the happy path. There's no coverage for token refresh, session expiry, concurrent login edge cases, or 2FA scenarios. I also have a completely untested data export feature that writes CSV files. Both are in the same Next.js app. /test and focus on auth depth improvements since it's mission-critical. Include the complete test file(s) in your reply.
