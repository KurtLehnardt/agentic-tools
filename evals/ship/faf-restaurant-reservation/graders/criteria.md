---
type: llm
weight: 1
---

PASS if:
- Phase 1 discovery states that 5 friends-and-family users with zero feature adoption is not a product-market-fit signal
- The reply states or shows the PMF assessment (as a logged Open Question for User, in questions.md content or inline in the reply)
- Phase 3 produces a prioritized 8-strategy document in the reply
- Prioritizes validation-before-scale as strategy #1
- Explicitly deprioritizes paid acquisition with reasoning
- Explicitly deprioritizes SEO with reasoning

FAIL if:
- Phase 1 treats 5 F&F users as positive signal
- Doesn't assess or question PMF status
- The reply never states or shows the Phase 1 PMF assessment
- Phase 3 strategy document is missing from the reply
- Recommends paid ads as near-term priority
- Prioritizes SEO when PMF not validated
- Skips validation phase and pushes to scale
