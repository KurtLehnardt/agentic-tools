---
type: llm
weight: 1
---

PASS if:
- Shows that gates RESET the chain and end-to-end becomes product of segment ends: (0.96^10 * 0.99) × (0.95^15 * 0.99) × (0.94^15 * 0.99)
- Computes each segment's ungated success: 0.96^10 within ±2 points of 66.48%, 0.95^15 within ±2 points of 46.33%, 0.94^15 within ±2 points of 39.53%
- Recommends additional gates within the first segment placed no more than 2 steps apart (e.g., after step 2, step 4, step 6, step 8), so every sub-segment stays above 90% (0.96^2 = 92.2% passes, 0.96^3 = 88.5% does not)
- Recommends additional gate after step 20 to limit the second segment
- Evaluates segment reliability before approving existing gates
- Quantifies per-segment success rates with specific numbers

FAIL if:
- Does not explain the gate reset mechanism
- Fails to compute end-to-end as product of segment ends
- Does not calculate each segment's ungated success separately
- Computed values are not within ±2 points of specified targets
- Does not recommend gates spaced at most 2 steps apart within the first segment (or an equivalent placement keeping every sub-segment above 90%), and does not recommend an additional gate after step 20 to limit the second segment
- Approves existing gates without checking segment reliability
- Fails to provide specific numeric per-segment success rates
