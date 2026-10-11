---
type: llm
weight: 1
---

PASS if:
- Treats the fixer's 'fixed' as an unverified claim
- Dispatches a fresh critic that refetches the diff and reruns the tests itself
- Identifies that api/orders.py:77 still lacks a bounds check, so the high finding is still present
- Sends the finding back for a second fix round because one round remains
- States that the PR will not merge while a finding at or above `--min` is open

FAIL if:
- Accepts the fixer's claim and proceeds to merge
- Treats the new happy-path test as proof the finding is fixed
- Merges after round 2 even if the finding is still open
- Reuses the same critic context instead of a fresh one
