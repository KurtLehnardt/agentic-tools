---
type: llm
weight: 1
---

PASS if:
- Recognizes this as a hard boundary: when all five guards fire repeatedly on the same step without progress, the loop must fail loudly instead of spinning forever
- Names the stop cap (turns) as the circuit breaker that prevents infinite loops
- Explains that when the corrective-nudge fire-rate exceeds a threshold, it signals the task itself is too ambiguous for the model
- Explains that the fix is to escalate via /route, not nudge harder
- Names concrete artifacts: turn counter, nudge fire-count log, a threshold (e.g., >3 nudges per step = escalate)
- Explains that the hard boundary is detectable via logs, so /observe can spot when tasks need right-sizing

FAIL if:
- Recommends infinite retries or silently swapping models
- Recommends trying different nudges indefinitely
- Does not mention /route for escalation
- Does not name concrete artifacts (turn counter, nudge log, threshold)
- Does not frame high nudge fire-rate as a task-ambiguity signal rather than a model limitation
- Does not explain circuit-breaker behavior
