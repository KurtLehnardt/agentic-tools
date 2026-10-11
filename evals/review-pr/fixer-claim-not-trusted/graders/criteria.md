---
type: llm
weight: 1
---

PASS if:
- Treats the fixer's 'fixed' as an unverified claim
- Dispatches a fresh critic that refetches the diff from the remote branch and reruns the tests itself
- Marks the prior high finding at api/orders.py:77 as `still present` with its own evidence
- Sends only that finding back to the fix step for a second round, because the default `--rounds` of 2 leaves one round
- States that the PR will not merge while a finding at or above `--min` is open

FAIL if:
- Accepts the fixer's claim and proceeds to merge
- Treats the new happy-path test as proof the finding is fixed
- Merges after round 2 even if the finding is still open
- Reuses the same critic context instead of a fresh one
