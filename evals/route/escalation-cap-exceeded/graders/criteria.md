---
type: llm
weight: 1
---

PASS if:
- Recognizes escalation cap exceeded (3 rungs: haiku→sonnet→opus)
- Recommends escalating to human
- States that failure at opus indicates the contract may be wrong, not the model
- Recommends reviewing contract/gate definition with human
- Recommends logging the decision

FAIL if:
- Recommends re-trying with higher effort on opus
- Recommends a 4th rung or custom model
- Suggests rolling back down and re-trying cheap
- Treats opus failure as a model problem rather than contract problem
