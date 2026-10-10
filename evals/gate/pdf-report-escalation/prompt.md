---
name: gate-pdf-report-escalation
description: "Test gate builder escalates unobservable criteria and gates observable ones separately"
tags: [gate]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

I'm building a PDF report generator. Acceptance criteria: Output PDF must be valid and readable, code should be elegant and maintainable, should support custom fonts, should handle very large documents efficiently. Can you gate this? Include the complete gate (code plus the command that runs it) in your reply.
