---
name: build-full-build-pipeline
description: Full 9-phase build pipeline orchestration with spec intake, requirements ledger, architect gate, decomposition, and merge
tags: [build]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 20
---

/build — I have a spec for a real-time notification service. The file spec.md defines 5 requirements: event subscriptions, delivery retry logic with exponential backoff, webhook payloads must match a published contract, P99 latency under 100ms, and audit logging. I've attached the spec. The codebase is Node.js + Express, existing tests run via npm test, OpenAPI schema is at docs/api.yaml. Walk me through the full build pipeline.
