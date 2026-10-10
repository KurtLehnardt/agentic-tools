---
type: llm
weight: 1
---

PASS if:
- PRD contains all 10 SKILL.md sections: Problem Statement, Success Criteria, Functional Requirements, Non-Functional Requirements, Technical Requirements, Service Manifest, Data Model, User Flows, Risks & Open Questions, Scope Boundaries
- Problem Statement identifies target as independent restaurants with 2-5 dining rooms
- Success Criteria include measurable outcomes: uptime SLA, no-show reduction %, concurrent reservations supported
- Functional Requirements numbered (FR-01 or similar), use RFC 2119 keywords (MUST/SHOULD/MAY), each with testable acceptance criteria (e.g., "SMS within 1 minute of scheduled time")
- Technical Requirements specify chosen stack
- Service Manifest names exact external services: Stripe, Twilio, Supabase
- Data Model shows key entities: restaurant, table, reservation, customer, preference
- User Flows cover: manager setup, customer booking, reminder delivery
- Risks section addresses: no-show mitigation effectiveness (highest-stakes), SMS failures, payment processing
- Scope Boundaries explicitly exclude: staff scheduling, kitchen display system, walk-in management

FAIL if:
- Uses vague language ("fast", "user-friendly") without measurable metrics
