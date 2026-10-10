---
name: sandbox-baseline-policy
description: Explain deny-by-default sandbox policy structure with proper filesystem and network config
tags: [sandbox]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

I need to set up a deny-by-default sandbox policy for an agent building a feature in our Node.js codebase. It should read the entire repo, write only to src/ and test/ directories, and has zero need for external network access. How do I configure this with sandbox?
