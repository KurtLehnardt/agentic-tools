---
type: llm
weight: 1
---

PASS if:
- Issues NARROW verdict
- Explicitly names the slice: "freelancer income tracking" or "freelancer-focused invoicing and tax prep"
- Explains why broad idea is crowded: high volume (45K) but saturated with 5+ strong incumbents, declining trend
- Explains why slice is open: 8,200 rising searches, incumbent solutions (YNAB, Wave, spreadsheets) each have specific failure modes for this use case
- Contrasts supply gaps: broad space (S=3, many competitors), slice (S=8, gap exists)
- Shows opportunity math improvement: broad (1,344 opportunity) vs narrow (4,032 opportunity)
- Cites the slice's payer and price point (freelancer, $12-20/month)
- Acknowledges that "personal finance app" without narrowing is ungradeable
- Recommends exploring the narrow slice next
- Provides one-sentence description of the MVP for the slice (e.g., "client-by-client invoice and tax tracking for 1099 workers")

FAIL if:
- Issues BUILD or PIVOT verdict
- Does not explicitly name the slice
- Recommends building the broad "personal finance app" as-is
- Claims the broad market is open (contradicted by 45K searches with 5+ incumbents)
- Does not contrast the two supply assessments (broad vs narrow)
- Does not show the opportunity score improvement
- Misses that Wave and YNAB fail the freelancer use case specifically
- Claims the narrow slice is also saturated
