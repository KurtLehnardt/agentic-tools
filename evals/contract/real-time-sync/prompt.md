---
name: contract-real-time-sync
description: Contract for real-time data sync in collaborative editor
tags: [contract]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

I need a contract for a feature: add real-time sync to our collaborative editor. Right now users get stale data when multiple people edit the same document. We want changes to propagate within 500ms with less than 1% data loss. The editor is built on Next.js with a PostgreSQL backend. Help me write a contract for this.
