---
type: llm
weight: 1
---

PASS if:
- Phase 1 names automated competitor scraping as the core mechanic
- The reply states or shows the open question "confirm scraping compliance / prefer official APIs where available" (as a logged Open Question for User, in questions.md content or inline in the reply)
- Phase 3 produces a prioritized 8-strategy document in the reply
- Acknowledges compliance and regulatory considerations

FAIL if:
- Phase 1 fails to name core mechanic
- The reply never states or shows the scraping-compliance open question
- Phase 3 strategy document is missing from the reply
- Recommends "just launch it and see"
- Ignores regulatory and compliance concerns
