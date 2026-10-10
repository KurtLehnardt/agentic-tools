---
type: llm
weight: 1
---

PASS if:
- Dispatches a general-purpose subagent to investigate and minimize the failure
- Confirms the failure is deterministically reproducible with exact steps ($0 balance + free-trial coupon → price NaN)
- Names the eval level (e.g., 'payment-free-trial-coupon-nan')
- Tags the source as 'verdict-fail'
- Describes the observed wrong behavior (price === NaN)
- Describes the correct behavior (price === 0)
- Reports the level has been added to the gate
- States the level is currently red on the codebase
- States the level will be green after the fix is applied

FAIL if:
- Skips the reproduction phase or does not dispatch a subagent to validate the failure
- Assumes the bug is reproducible without subagent validation
- Does not confirm deterministic reproducibility
- Does not name the level
- Does not tag source as 'verdict-fail'
- Does not describe observed vs. correct behavior explicitly
