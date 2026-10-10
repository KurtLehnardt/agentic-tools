---
name: gate-email-validator-boundaries
description: "Test gate for email validator with boundary cases and rejection paths"
tags: [gate]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

gate for an email validator function. spec: Accepts valid RFC 5322 emails, rejects invalid formats. Must handle: normal email, subdomain email, plus-addressing, edge cases (empty string, space, very long local part). Include the complete gate (code plus the command that runs it) in your reply.
