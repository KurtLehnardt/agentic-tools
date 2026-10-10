---
type: llm
weight: 1
---

PASS if:
- Recognizes lowercase trigger phrase "find me a market gap" as valid invocation (per SKILL.md frontmatter)
- Matches informal, lowercase-heavy register in response (mirror the user's tone)
- Identifies this as validation mode (quoted idea = validation, not discovery)
- Reports validation structure: query cluster, supply assessment, four subscores, verdict
- Labels volumes as Estimated (no measured provider)
- Acknowledges high rising demand (6,200/month, rising = strong D score)
- Identifies supply gap: Peloton wrong audience, YouTube not personalized, no dedicated senior-focused app
- Notes SERP composition signal: listicles outnumber tools (gap indicator)
- Issues BUILD verdict or (cautiously) acknowledges strong opportunity
- Subscores: D=8 (rising 6,200), S=8 (only YouTube generics, no senior-focused competitor), M=8 (clear payer, senior with disposable income, stated $10-15/month), B=9 (stated 2-week MVP on Next+Supabase)
- Calculates opportunity = 8*8*8*9 = 4,608 (strong)
- Acknowledges all inline data was supplied (no missing research needed)

FAIL if:
- Does not recognize lowercase trigger phrase as valid
- Treats as discovery mode instead of validation
- Uses formal register when user input is informal (tone mismatch)
- Labels volumes as Data (no provider configured)
- Issues DON'T BUILD verdict (contradicted by rising demand, clear payer, strong supply gap)
- Omits subscores
- Scores Demand below 7 (rising 6,200 searches)
- Scores Build ease below 8 (stated 2-week MVP on known stack)
- Does not multiply subscores to compute opportunity
