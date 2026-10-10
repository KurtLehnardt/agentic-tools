---
type: llm
weight: 1
---

PASS if:
- Reply walks through the full 7-phase pipeline despite the sloppy lowercase prompt
- Reply produces a Requirements Ledger (v1) with the 4 stated requirements (retry on failure, persist to postgres, process in order, HTTP endpoint) and presents it for sign-off
- Each requirement is classified as BINDING or GUIDANCE
- Reply shows an example architect gate verdict with a `verdict` field of APPROVED or REVISE
- If the shown example is REVISE, blocking issues are included with evidence
- Reply names decomposed tasks with consistent identifiers (t01, t02, etc.)
- Each named task carries a complexity tier (S/M/L) and a model tier assignment (haiku/sonnet/opus)
- Reply states workers self-run gate-check.sh before declaring done, and that a mechanical gate failure goes straight back to the worker, not to a judge
- Reply shows example judge verdicts per task with requirement status (MET/NOT_MET/DEFERRED)
- Reply states commits follow the conventional format with [R-XXX] requirement tags
- Reply states the baseline is captured before worker dispatch

FAIL if:
- Any 7-phase stage is abbreviated or skipped
- Requirements Ledger is absent or lists fewer than 4 requirements
- Ledger lacks BINDING/GUIDANCE classification
- No example architect gate verdict is shown
- Task names lack a consistent naming convention
- Task complexity or model tier is missing for any named task
- Reply claims gate-check.sh has already run and passed, rather than describing it as the self-verification step workers run
- Judge verdict examples omit requirement status markers
- Reply's commit convention omits [R-XXX] requirement identifiers
- Baseline capture is missing from the described pipeline
