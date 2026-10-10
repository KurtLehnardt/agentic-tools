---
type: llm
weight: 1
---

PASS if:
- Routes the owner to opus@high
- Routes the verdict to opus@high
- Explicitly states that verdict must run at the top rung regardless of owner model
- Explains that the gatekeeper role requires the strongest model
- Identifies high stakes (payment, $75M ARR, silent failures cost thousands per hour)
- States that the expensive judge is the insurance policy

FAIL if:
- Routes the owner to a cheaper model (haiku, sonnet)
- Routes the verdict to sonnet, haiku, or local
- Suggests the verdict can run on a cheaper model to save cost
- Treats verdict as same tier as owner
- Underestimates the stakes of payment infrastructure
