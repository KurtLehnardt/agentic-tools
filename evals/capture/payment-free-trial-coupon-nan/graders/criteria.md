---
type: llm
weight: 1
---

PASS if:
- States that the failure was minimized to its smallest reproducing input — directly or by describing a dispatched subagent's findings — and shows that minimal input ($0 balance + free-trial coupon)
- Confirms the failure is deterministically reproducible with exact steps ($0 balance + free-trial coupon → price NaN)
- Names the eval level (e.g., 'payment-free-trial-coupon-nan')
- Tags the source as 'verdict-fail'
- Describes the observed wrong behavior (price === NaN)
- Describes the correct behavior (price === 0)
- States that the level has been added to the gate
- States the level is currently red on the codebase
- States the level will be green after the fix is applied

FAIL if:
- Skips confirming the minimal repro (neither reasons through it directly nor describes a subagent's validation of it)
- Assumes the bug is reproducible without stating a minimization/validation step
- Does not confirm deterministic reproducibility
- Does not name the level
- Does not tag source as 'verdict-fail'
- Does not describe observed vs. correct behavior explicitly
- Does not state that the level was added to the gate
