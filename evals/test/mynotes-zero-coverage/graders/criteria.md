---
type: llm
weight: 1
---

PASS if:
- Produces Phase 1 coverage analysis mapping all 5 modules (lib/auth.ts, lib/db.ts, api/routes/notes.ts, components/Editor.tsx, utils/formatting.ts)
- Categorizes each module with coverage depth assessment (UNTESTED, SHALLOW, ADEQUATE, or THOROUGH)
- Assigns correct risk levels (HIGH: auth.ts and notes.ts route; MEDIUM: db.ts; LOW: Editor.tsx and formatting.ts)
- Phase 2 provides a prioritized test plan with auth and API route as first targets
- Phase 3 generates test files with unit tests for auth covering login, token validation, and refresh flow
- Phase 3 generates integration tests for notes route covering create, read, update, delete with auth checks
- Phase 4 states the validation command it would run and that generated tests must pass before reporting, without claiming a run it did not perform

FAIL if:
- Does not map all 5 modules in Phase 1 coverage analysis
- Does not categorize coverage depth for each module
- Fails to assign appropriate risk levels to modules
- Does not prioritize auth and API route in Phase 2
- Generates test files that modify any of the 5 source files
- Phase 4 claims to have actually run tests or executed the validation command
