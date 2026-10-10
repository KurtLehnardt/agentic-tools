---
type: llm
weight: 1
---

PASS if:
- Shows that gates RESET the chain and end-to-end becomes product of segment ends: (0.96^10 * 0.99) × (0.95^15 * 0.99) × (0.94^15 * 0.99)
- Computes each segment's ungated success: 0.96^10 within ±2 points of 61.27%, 0.95^15 within ±2 points of 46.33%, 0.94^15 within ±2 points of 39.53%
- Recommends additional gates after step 2 and step 5 to keep the first segment above 90%
- Recommends additional gate after step 20 to limit the second segment
- Evaluates segment reliability before approving existing gates
- Quantifies per-segment success rates with specific numbers

FAIL if:
- Does not explain the gate reset mechanism
- Fails to compute end-to-end as product of segment ends
- Does not calculate each segment's ungated success separately
- Computed values are not within ±2 points of specified targets
- Does not recommend additional gates after steps 2, 5, or 20 as needed
- Approves existing gates without checking segment reliability
- Fails to provide specific numeric per-segment success rates
