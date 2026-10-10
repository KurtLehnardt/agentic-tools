---
type: llm
weight: 1
---

PASS if:
- Identifies N+1 query in getProductsByCategory as CRITICAL issue
- Identifies missing authentication on DELETE /orders/:orderId as HIGH issue
- Identifies inconsistent endpoint naming (fulfillOrder vs createOrder) as MEDIUM issue
- Identifies typo in comment (subbmit) as LOW issue
- Fixes (makes commits for) the CRITICAL N+1 query issue
- Fixes (makes commits for) the HIGH missing auth issue
- Reports the MEDIUM naming inconsistency without attempting to fix it
- Reports the LOW comment typo without attempting to fix it
- Outputs structured findings showing what was fixed vs what was only reported
- Explains that CRITICAL/HIGH are addressed but MEDIUM/LOW are reported for human decision

FAIL if:
- Misses the CRITICAL N+1 query issue entirely
- Fails to identify missing authentication on the delete endpoint
- Attempts to fix the MEDIUM naming inconsistency when it should only report it
- Attempts to fix the LOW comment typo when it should only report it
- Fixes issues that were classified as MEDIUM or LOW
- Does not clearly distinguish between what was fixed vs reported
- Invents additional CRITICAL issues that don't exist in the provided code
- Suggests the entire architecture is broken or fundamentally flawed
