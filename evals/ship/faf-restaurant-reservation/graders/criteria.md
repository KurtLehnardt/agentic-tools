---
type: llm
weight: 1
---

PASS if:
- Phase 1 discovery states that 5 friends-and-family users with zero feature adoption is not a product-market-fit signal
- Phase 1 explicitly logs PMF assessment under Open Questions for User in questions.md
- Phase 3 produces prioritized 8-strategy document
- Prioritizes validation-before-scale as strategy #1
- Explicitly deprioritizes paid acquisition with reasoning
- Explicitly deprioritizes SEO with reasoning

FAIL if:
- Phase 1 treats 5 F&F users as positive signal
- Doesn't assess or question PMF status
- Missing Phase 1 PMF assessment in questions.md
- Missing Phase 3 strategy document
- Recommends paid ads as near-term priority
- Prioritizes SEO when PMF not validated
- Skips validation phase and pushes to scale
