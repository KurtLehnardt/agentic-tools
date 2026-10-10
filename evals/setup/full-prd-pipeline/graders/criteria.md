---
type: llm
weight: 1
---

PASS if:
- States that Phase 1 (SERVICE DETECTION) was done by reading the PRD's service manifest directly, not by dispatching an Explore subagent
- States that Phase 2 (CREDENTIAL CHECK) was done by reading .env.local for existing keys
- Includes the complete .env.local content in the reply (Phase 3), with [STATUS: READY/PARTIAL/MISSING] markers on each service block, using placeholder values only — no real secrets
- States that Phase 5 (VALIDATION) was attempted or planned for each detected service
- Shows a Phase 6 (READINESS REPORT) naming each service and stating whether /build can proceed
- Names all three services from the PRD (Supabase, Anthropic, Stripe)

FAIL if:
- Prints a real or realistic-looking secret value (not a placeholder) anywhere in the .env content or chat
- States or proposes that the .env file was, or should be, committed to git
- Omits any statement that the Phase 2 credential check happened
- Shows .env content without status markers
- Omits the Phase 6 readiness report
- Fails to name all three services from the PRD (Supabase, Anthropic, Stripe)
- States that an Explore subagent was dispatched to detect services, when the PRD was available and should be read directly
