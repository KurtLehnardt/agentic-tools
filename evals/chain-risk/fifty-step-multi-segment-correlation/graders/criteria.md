---
type: llm
weight: 1
---

PASS if:
- Computes end-to-end success as the product of per-segment p^n terms: (0.98^5) * (0.92^10) * (0.95^20) * (0.94^15)
- States the result within ±2 percentage points of 5.56%
- Calculates each per-segment p^n separately and identifies which segments fail the 95% target
- Identifies inference (0.92 per step) as the bottleneck
- Notes that correlated failures from bad inference data cannot be captured by p^n alone and identifies this as a LIMIT of the model, not a fix
- Recommends either (a) gate after inference with correction loop, or (b) escalate inference quality before gating strategy
- Explicitly acknowledges correlation risk and does not present p^n numbers as gospel

FAIL if:
- Does not compute end-to-end success as the product of per-segment p^n terms
- Result is not within ±2 percentage points of 5.56%
- Fails to show per-segment p^n calculations separately
- Does not identify which segments fall short of the 95% target
- Does not recognize inference as the bottleneck
- Fails to acknowledge that correlated failures cannot be captured by p^n alone
- Presents p^n numbers as definitive without acknowledging correlation risk
- Does not recommend a gate placement strategy or quality escalation approach
