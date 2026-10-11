---
type: llm
weight: 1
---

PASS if:
- States the critical and high findings (SQL injection, missing auth check) are sent to a fix subagent
- States the medium, low and nit findings are not fixed under --min high
- States the below-threshold findings are still reported to the user
- States the critic re-reviews the PR after the fix before merge

FAIL if:
- Sends the medium finding to the fix subagent
- Fixes the nitpick
- Ignores the --min argument and uses the default medium threshold
