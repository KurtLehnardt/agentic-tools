---
type: llm
weight: 1
---

PASS if:
- Identifies step/workflow enforcement as the relevant guard
- Explains that the loop must check acceptance criteria (not just model claims) before allowing 'done'
- Names the concrete check: acceptance criteria must be green before 'done' is legal
- Frames this as a guardrail problem, not a task-specification problem (the loop blocks the illegal transition)
- Explains what the worker outputs (step name, action, result) and how the harness validates the next step is legal
- Recommends not weakening acceptance criteria or skipping steps

FAIL if:
- Does not identify step/workflow enforcement as the relevant guard
- Treats this as a task-specification problem rather than a guardrail/loop problem
- Recommends weakening acceptance criteria
- Recommends skipping step 5
- Does not explain the harness-side check for criteria before allowing 'done'
- Does not explain the worker output shape and harness validation
