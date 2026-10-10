---
type: llm
weight: 1
---

PASS if:
- Includes the complete CONTRACT-*.md content in the reply, with five distinct sections
- Objective/Intent section explains why sub-500ms sync matters to collaboration experience and user retention
- Contains numbered Acceptance Criteria list where each criterion is machine-checkable
- Acceptance Criteria include measurable examples like "replication latency <500ms on synthetic 50-concurrent-user load test" and "message delivery success rate >99.9%"
- Contains Gate section with single executable check that would fail if implementation was stubbed with hardcoded or fake in-memory data
- Contains Out of Scope section with 3+ explicit non-goals (e.g., "mobile client implementation", "offline-first conflict resolution")
- Contains Owner/Gatekeeper split clarifying who builds versus who verifies
- All acceptance criteria are testable and quantified, not vague adjectives

FAIL if:
- Includes implementation details that specify how to build (e.g., "use WebSocket", "add Redis queue", "implement vector clock")
- Uses vague adjectives without measurable thresholds
- Gate is stub-passable (would allow hardcoded latency return or fake in-memory replication)
- Missing any of the five required sections (Objective, Criteria, Gate, Out of Scope, Owner/Gatekeeper)
- Out of Scope section has fewer than 3 items
- Acceptance Criteria are subjective or unverifiable without numbers/commands
