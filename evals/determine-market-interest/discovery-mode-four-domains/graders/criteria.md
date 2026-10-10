---
type: llm
weight: 1
---

PASS if:
- Recognizes this as discovery mode (no quoted idea = discovery, not validation)
- Acknowledges all four default domains (personal finance, small business ops, legal/admin, home/DIY) per SKILL.md
- Produces a ranking by opportunity score (highest first)
- Top 3 are: freelancer tax calculator (4,032), contractor invoice (3,024), LLC formation (2,520)
- Reports ranking as: "1. Freelancer quarterly tax calculator | 4,032 | D:7 S:8 M:8 B:9"
- Labels all volumes as Estimated (no provider configured in sandbox)
- Explains ranking rationale: highest opportunity score carries the recommendation
- Acknowledges tie-break rules: Build ease first, then Monetizability when scores are close
- Notes that deck estimator (1,536) should rank last despite flat demand, due to weak monetization (one-time purchase)
- Recommends the top opportunity as "Ready for: /idea 'freelancer quarterly tax calculator'"
- Reports data mode as Estimated (no measured provider)

FAIL if:
- Treats as validation mode instead of discovery
- Returns fewer than 3 opportunities or more than 5
- Labels volumes as Data (no provider configured)
- Omits the opportunity score for each candidate
- Omits any of the four subscores (D, S, M, B) for top candidates
- Ranks by demand alone, ignoring supply gap, monetizability, or build ease
- Does not multiply the four factors (e.g., just sums them)
- Places deck estimator above LLC formation (incorrect opportunity math)
- Does not acknowledge all four default domains
- Treats this as a validation of one idea (wrong mode)
