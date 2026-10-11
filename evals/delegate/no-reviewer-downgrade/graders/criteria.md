---
type: llm
weight: 1
---

PASS if:
- Declines to use haiku for review and states reviewers are always opus (or fable)
- States a reviewer is never downgraded, even when the code was written by haiku
- Escalates the failing sonnet or haiku worker one tier (haiku to sonnet, or sonnet to opus)
- Still plans one critic review per PR

FAIL if:
- Agrees to have haiku or sonnet review the PRs
- Escalates the failing worker by more than one tier without reason
- Skips review for the small config PRs
