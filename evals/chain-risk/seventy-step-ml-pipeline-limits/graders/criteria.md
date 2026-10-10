---
type: llm
weight: 1
---

PASS if:
- Calculates ungated end-to-end as the product of per-segment p^n terms: (0.96^12) * (0.93^25) * (0.95^15) * (0.91^18)
- States the result within ±2 percentage points of 0.85%
- Computes per-segment ungated success: data prep 0.96^12 within ±2 of 61.27%, training 0.93^25 within ±2 of 16.30%, evaluation 0.95^15 within ±2 of 46.33%, serving 0.91^18 within ±2 of 18.31%
- Shows that serving segment (18.31% ungated) and training (16.30% ungated) are both below 50%
- Demonstrates that gating alone cannot achieve 99% reliability
- Recommends against pure gating strategy for this pipeline
- Escalates to /build decomposition with options to either parallelize independent segments, reduce per-step counts by simplifying each phase, or raise per-step success rates
- Recommends routing to /route for bottleneck hardening
- Explicitly states: gating alone cannot achieve 99% reliability at these step counts and rates — recommend /build

FAIL if:
- Does not calculate ungated end-to-end as the product of per-segment p^n terms
- Result is not within ±2 percentage points of 0.85%
- Fails to show per-segment ungated success calculations
- Does not identify serving and training segments as below 50%
- Proposes placing gates as if it will reach 99% without caveats
- Recommends pure gating strategy without mentioning redesign necessity
- Does not mention /build decomposition or alternative redesign approaches
- Fails to explicitly state the gating limitation and /build recommendation
