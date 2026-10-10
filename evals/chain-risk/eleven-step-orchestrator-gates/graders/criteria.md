---
type: llm
weight: 1
---

PASS if:
- Computes ungated end-to-end success rate using p^n formula
- Shows the break-even step count where success drops below 90%: 2 steps at p=0.95, 3 at p=0.97
- Provides a table or curve showing how success decays at 0.97 average rate
- Recommends specific gate positions (e.g., after orchestrator, after workers, before merge) with segment lengths that each stay above 90%

FAIL if:
- Does not apply the p^n formula to compute end-to-end reliability
- Does not identify or show break-even step counts
- Fails to provide a visual representation (table or curve) of success decay
- Does not recommend specific gate positions with explained placement
- Only describes the mathematical concept without applying it to the 11-step pipeline
