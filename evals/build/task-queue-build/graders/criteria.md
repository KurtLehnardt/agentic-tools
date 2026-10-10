---
type: llm
weight: 1
---

PASS if:
- Output executes the full 7-phase pipeline despite sloppy lowercase input
- Requirements Ledger (v1) is produced and signed off with 4 requirements listed
- Each requirement is classified as BINDING or GUIDANCE
- Architect gate verdict is provided with verdict field set to APPROVED or REVISE
- If REVISE, blocking issues are included with evidence
- Tasks are decomposed into named identifiers (t01, t02, etc.)
- Each task has complexity tier (S/M/L) and model tier assignment (haiku/sonnet/opus)
- Workers execute with gate-check.sh and mechanical checks pass
- Judge verdicts are provided per task showing requirement status (MET/NOT_MET/DEFERRED)
- Commits follow conventional format with [R-XXX] requirement tags
- Baseline is captured before worker dispatch

FAIL if:
- Any 7-phase stage is abbreviated or skipped
- Requirements Ledger is absent or incomplete (fewer than 4 requirements)
- Ledger lacks BINDING/GUIDANCE classification
- No architect gate verdict is provided
- Task names lack consistent naming convention (t01, t02, etc.)
- Task complexity or model tier is missing
- gate-check.sh shows failures that block the task
- Judge verdicts omit requirement status markers
- Commits lack [R-XXX] requirement identifiers
- Baseline capture is skipped
