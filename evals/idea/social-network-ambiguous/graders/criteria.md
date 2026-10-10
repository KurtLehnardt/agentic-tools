---
type: llm
weight: 1
---

PASS if:
- PRD acknowledges ambiguous input and requires rigorous questioning before assumptions
- Phase 1 identifies multiple ambiguities in the requirement
- Phase 2 produces PRD with all 10 SKILL.md sections
- Risks & Open Questions section lists 5+ blocking questions covering: target user demographics, real-time vs. async messaging, mobile-first/web/both, monetization model, scale targets
- Problem Statement defines a specific target user based on questioning
- Success Criteria are measurable, not vague adjectives
- Functional Requirements numbered, RFC 2119 keywords present
- Technical Requirements specify stack choices ONLY after addressing questioning
- Service Manifest, Data Model, User Flows, Non-Functional Requirements, Scope Boundaries all present
- Demonstrates understanding that ambiguity requires dialogue before specification

FAIL if:
- Assumes PostgreSQL, Redis, React, or specific architecture without user input
- Skips target user definition
- Skips measurable success criteria or leaves them vague
