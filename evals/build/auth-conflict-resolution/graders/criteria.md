---
type: llm
weight: 1
---

PASS if:
- Process proceeds to Phase 0 and builds initial Requirements Ledger
- A SPEC_CONFLICT is detected and explicitly emitted when an architectural contradiction is found (e.g., R-003 IP re-auth vs stateless tokens)
- SPEC_CONFLICT output includes the requirement ID and clear explanation of the conflict
- On conflict, the task stops and escalates to human rather than resolving silently
- If ledger is amended by human, a new ledger version (v2, v3, etc.) is generated with date and approved-by annotation
- Amended ledger explicitly lists which tasks are invalidated and must re-run
- Build resumes with the revised ledger
- Final verdict covers all requirements with evidence including file paths and line numbers
- All requirements are resolved either by implementation or explicit specification amendment

FAIL if:
- SPEC_CONFLICT is not detected when present (e.g., IP re-auth cannot coexist with stateless design)
- Conflict is silently resolved without human approval or explicit amendment notation
- R-003 is downgraded or dropped without human approval and logged amendment
- Build completes while a spec conflict remains unresolved
- Ledger amendment lacks date, approved-by annotation, or invalidated task list
- Final verdict contains DEFERRED status for requirements that should be MET or explicitly amended
- Conflict detection does not stop execution at the point of discovery
