---
name: test-mynotes-zero-coverage
description: Analyze zero test coverage on a Next.js SaaS application and prioritize high-risk modules
tags: [test]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

I've built a Next.js SaaS application at ~/work/mynotes with these modules: lib/auth.ts, lib/db.ts, api/routes/notes.ts, components/Editor.tsx, and utils/formatting.ts. I have zero test coverage. Can you /test this thing and tell me where the biggest gaps are?
