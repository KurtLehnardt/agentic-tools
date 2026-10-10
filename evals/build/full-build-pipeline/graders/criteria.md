---
type: llm
weight: 1
---

PASS if:
- Output references all 9 phases by name: SPEC INTAKE, ROADMAP, ARCHITECT GATE, PRODUCT GATE, DECOMPOSE, DISPATCH PLAN, SWARM, GATE+JUDGE, MERGE & VERIFY
- Requirements Ledger (v1) is produced with 5 rows mapping each requirement to testable acceptance criteria
- Each requirement in the ledger is classified as either BINDING or GUIDANCE
- Verification commands are identified from config.json for each requirement
- An `|||ARCHITECT_VERDICT|||` block is emitted with `verdict` field set to APPROVED or REVISE
- If REVISE, blocking issues are listed with explanation
- Decomposed tasks are named (t01, t02, etc.) with complexity tiers (S/M/L) and model assignments (haiku/sonnet/opus)
- baseline.json is captured before dispatch
- All workers report reaching TASK_COMPLETE state
- Judge verdicts show `verdict: APPROVED` and `status: MET` for all non-deferred requirements
- Merged branches include commits following conventional format with requirement tags like `feat(tNN): [R-001] description`

FAIL if:
- Any of the 9 phases is skipped or not explicitly named
- Requirements Ledger is absent or incomplete
- Ledger does not classify each requirement as BINDING or GUIDANCE
- Verification commands are missing or not sourced from config.json
- No architect verdict block is provided
- Architect verdict does not include blocking issues when REVISE is set
- Tasks lack complexity tiers or model tier assignments
- baseline.json is not captured before dispatch
- Any worker fails to reach TASK_COMPLETE
- Judge verdicts contain DEFERRED or NOT_MET for core requirements that should be MET
- Merged commits lack requirement ID tags [R-XXX]
