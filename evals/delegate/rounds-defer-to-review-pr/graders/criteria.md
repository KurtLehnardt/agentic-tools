---
type: llm
weight: 1
---

PASS if:
- States the round limit is owned by `/review-pr`, whose `--rounds` default is 2
- Says one more fix round remains for the eslint PR
- Says the PR is reported as blocked, not merged, if the high finding is still open when rounds run out
- Says `--rounds` is passed to `/review-pr` only if the user asked for a specific number

FAIL if:
- States a limit of three rounds
- Merges the PR with the high finding still open
- Loops without a round limit
