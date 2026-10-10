---
type: llm
weight: 1
---

PASS if:
- Reply names and walks through all 9 phases in order: SPEC INTAKE, ROADMAP, ARCHITECT GATE, PRODUCT GATE, DECOMPOSE, DISPATCH PLAN, SWARM, GATE + JUDGE, VERIFY & DELIVER
- Reply produces a Requirements Ledger (v1) with 5 rows, one per named requirement, each with a testable acceptance criterion
- Reply classifies each ledger row as BINDING or GUIDANCE
- Reply states verification commands are sourced from config.json (detected from the repo's own tooling), not invented ad hoc
- Reply shows an example `|||ARCHITECT_VERDICT|||` block, in the documented shape, with a `verdict` field of APPROVED or REVISE
- If the shown example verdict is REVISE, blocking issues are listed with explanation
- Reply names decomposed tasks (t01, t02, ...) each with a complexity tier (S/M/L/XL) and a model assignment (haiku/sonnet/opus)
- Reply states baseline.json is captured before any worker is dispatched
- Reply describes the worker protocol: a worker's final message starts with TASK_COMPLETE, SPEC_CONFLICT, or BLOCKED, and a task is only merged after judge APPROVED, never on worker completion alone
- Reply shows an example `|||JUDGE_VERDICT|||` (or otherwise describes its shape) with MET/NOT_MET/DEFERRED status per requirement
- Reply states the commit convention carries requirement tags, e.g. `feat(tNN): [R-001] description`

FAIL if:
- Any of the 9 phases is skipped or not explicitly named
- Requirements Ledger is absent, incomplete, or missing BINDING/GUIDANCE classification
- Reply does not state that verification commands come from config.json
- No architect verdict block/shape is shown, or a shown REVISE example omits blocking issues
- Decomposed tasks lack complexity tiers or model-tier assignments
- Reply does not mention capturing baseline.json before dispatch
- Reply claims workers have already reached TASK_COMPLETE or were already merged within this same turn, rather than describing the protocol that would produce that outcome
- Reply's described judge-verdict shape omits MET/NOT_MET/DEFERRED status
- Reply's commit convention omits requirement ID tags
