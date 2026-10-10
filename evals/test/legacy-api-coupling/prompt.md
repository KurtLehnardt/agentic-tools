---
name: test-legacy-api-coupling
description: Assess untestable legacy code with tight coupling and recommend refactoring
tags: [test]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

I have this legacy API route that's a 200-line file with no dependency injection. It directly imports the database, makes HTTP calls to a third-party API inline, logs directly to stdout, and mixes HTTP request handling with business logic. I need tests but the code is too tangled. What do I do? If you write any tests, include the complete test file(s) in your reply.
