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
- The reply presents the code of a hollow stub that hardcodes total=45 and skips validation, and identifies, by name, the specific assertion that rejects it (e.g., the InvalidProductID test), showing the reasoning for why that assertion catches it. Alternatively, building a stub-proving mode into the gate itself (e.g. a `--prove-stubs` flag) and naming the assertions that mode relies on is equally sufficient.
- Uses concrete numeric equality rather than adjectives like 'correct'
- The reasoning shown demonstrates the stub fails specifically on a negative-path assertion, not the positive-path one

FAIL if:
- Gate does not include both positive AND negative path assertions
- Positive path assertion does not require exact numeric equality (e.g., allows 'approximately' $45)
- Does not test rejection of invalid product IDs
- Does not test prevention of negative totals
- Does not test empty cart returns exactly 0
- A stub hardcoding total=45 would pass the gate as shown
- Neither presents the stub's code with the named assertion that rejects it and the reasoning, nor provides a stub-proving mode naming the assertions it relies on
- Relies on adjectives like 'correct' instead of concrete numeric values
