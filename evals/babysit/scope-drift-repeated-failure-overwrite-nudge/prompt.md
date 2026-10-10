---
name: babysit-scope-drift-repeated-failure-overwrite-nudge
description: Detect SCOPE DRIFT and REPEATED FAILURE; overwrite stale NUDGE.md; log previous problem type
tags: [babysit]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

babysit: build/t05-payment-processor has modified src/auth/login.ts (outside its scope—only owns src/payments/*), and build/t06-email-service made 5 commits all named 'fix(t06): step 2' without advancing to step 3. Previous check found t05 stalled, now it has uncommitted changes. Check both. Include the complete NUDGE.md content for t05 and t06 in your reply.
