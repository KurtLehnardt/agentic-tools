---
name: gate-user-auth-endpoint
description: "Test gate builder produces stub-proof test suite for auth endpoint validation"
tags: [gate]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

Build me a gate for a user auth endpoint. Criteria: POST /auth/login with valid email and password returns 200 with access_token and user_id fields. Should reject requests with missing email or password. Should not return plain-text passwords in response.
