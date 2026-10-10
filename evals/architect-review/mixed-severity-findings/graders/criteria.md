---
type: llm
weight: 1
---

PASS if:
- Identifies N+1 query in getProductsByCategory as CRITICAL issue
- Identifies missing authentication on DELETE /orders/:orderId as HIGH issue
- Identifies inconsistent endpoint naming (fulfillOrder vs createOrder) as MEDIUM issue
- Identifies typo in comment (subbmit) as LOW issue
- Presents the corrected code inline for the CRITICAL N+1 query issue (e.g. a JOIN or batched query replacing the per-category loop)
- Presents the corrected code inline for the HIGH missing auth issue (e.g. adding an auth middleware/check to the DELETE route)
- Reports the MEDIUM naming inconsistency without presenting corrected code for it
- Reports the LOW comment typo without presenting corrected code for it
- Structures the reply so it's clear which findings come with corrected code (fixed) and which are reported only
- Explains that CRITICAL/HIGH are addressed with inline fixes but MEDIUM/LOW are reported for human decision

FAIL if:
- Misses the CRITICAL N+1 query issue entirely
- Fails to identify missing authentication on the delete endpoint
- Presents corrected code for the MEDIUM naming inconsistency when it should only report it
- Presents corrected code for the LOW comment typo when it should only report it
- Presents corrected code for issues classified as MEDIUM or LOW
- Does not clearly distinguish between what was fixed (with corrected code) vs reported
- Invents additional CRITICAL issues that don't exist in the provided code
- Suggests the entire architecture is broken or fundamentally flawed
