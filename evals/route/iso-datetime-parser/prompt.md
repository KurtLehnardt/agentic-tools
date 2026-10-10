---
name: route-iso-datetime-parser
description: Route a simple ISO 8601 parser to the cheapest model
tags: [route]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

I need a TypeScript utility function that parses ISO 8601 datetime strings and returns a native Date object. Single function, about 30 lines, needs unit tests for valid dates, invalid formats, and edge cases like leap seconds. Low risk — internal tooling, not user-facing. Which model should I route this to, and at what effort level?
