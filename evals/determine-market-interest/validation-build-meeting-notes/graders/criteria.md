---
type: llm
weight: 1
---

PASS if:
- Issues BUILD verdict
- Correctly identifies this as validation mode (not discovery)
- Acknowledges high problem-intent volume (8,200 rising searches = strong demand signal per demand-estimation.md)
- Labels volumes as Estimated (no measured provider configured)
- Identifies supply gap: 2 paid tools, both with specific failure modes (expensive, accuracy, UX)
- Notes SERP composition signal: articles outnumber tools, indicating gap
- Reports four subscores independently (D, S, M, B) before multiplying
- Scores Demand as 7-9 (strong rising volume)
- Scores Supply gap as 6-8 (competitors exist but weak on multiple factors)
- Scores Monetizability as 8-10 (clear willingness to pay, subscription or usage-based pricing viable)
- Scores Build ease as 7-9 (buildable on stated Next.js + Supabase stack in days)
- Calculates opportunity as product of four factors (minimum 2352 for viable BUILD on these scores)
- Justifies BUILD verdict with reasoning connecting the four factors and the gap
- Acknowledges payer and price point from the prompt data

FAIL if:
- Issues NARROW or PIVOT verdict
- Labels volumes as Data (no provider configured in sandbox)
- Omits any of the four subscores
- Scores Demand below 6 (contradicts rising 8,200 searches)
- Scores Monetizability below 7 (contradicts clear pricing model)
- Scores Build ease below 5 (contradicts stated feasibility on Next.js + Supabase)
- Does not multiply subscores to compute opportunity
- Misses or minimizes the supply gap (both competitors have documented weaknesses)
- Claims the market is saturated (contradicted by SERP composition and volume)
- Treats this as discovery mode instead of validation
