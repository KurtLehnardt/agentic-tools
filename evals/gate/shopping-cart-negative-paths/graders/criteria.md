---
type: llm
weight: 1
---

PASS if:
- Produces an executable gate with assertions covering both positive and negative paths
- Positive path: valid products sum to exact numeric value (e.g., $10 + $20 + $15 = $45, not 'approximately' or 'around' $45)
- Negative path assertion (a): adding product with invalid product ID returns an error
- Negative path assertion (b): attempting to set or permit total < 0 fails
- Negative path assertion (c): empty cart returns exactly 0
- Demonstrates a hollow stub that hardcodes total=45 and skips validation fails the gate
- Names the exact assertion that rejected the stub (e.g., 'InvalidProductID test rejected stub')
- Uses concrete numeric equality rather than adjectives like 'correct'
- Proves stub fails specifically on negative-path assertions

FAIL if:
- Gate does not include both positive AND negative path assertions
- Positive path assertion does not require exact numeric equality (e.g., allows 'approximately' $45)
- Does not test rejection of invalid product IDs
- Does not test prevention of negative totals
- Does not test empty cart returns exactly 0
- A stub hardcoding total=45 would pass the gate
- Does not name which specific assertion rejected the stub
- Relies on adjectives like 'correct' instead of concrete numeric values
- Does not demonstrate Phase 2 adversarial stub failure
