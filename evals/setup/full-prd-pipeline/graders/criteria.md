---
type: llm
weight: 1
---

PASS if:
- Executes Phase 1 (SERVICE DETECTION) by reading PRD service manifest directly
- Executes Phase 2 (CREDENTIAL CHECK) by reading .env.local for existing keys
- Generates .env.local file (Phase 3) with [STATUS: READY/PARTIAL/MISSING] markers on each service block
- Includes Phase 5 (VALIDATION) attempts for detected services
- Outputs Phase 6 (READINESS REPORT) naming each service and whether /build can proceed
- Reads the PRD directly rather than dispatching Explore subagent

FAIL if:
- Outputs actual secret values into chat (printed plaintext API keys, tokens, or credentials)
- Commits .env file to git or proposes committing it
- Skips Phase 2 credential check
- Generates .env without status markers
- Does not output Phase 6 readiness report
- Fails to identify all three services from PRD (Supabase, Anthropic, Stripe)
