---
type: llm
weight: 1
---

PASS if:
- Names all five guards: response validation, rescue parsing, corrective retry nudges, step/workflow enforcement, context compaction
- Explains that rescue parsing extracts intent from near-miss formats (fenced JSON with prose, trailing commas, off-by-one field names) without re-inferring
- Explains that rescue avoidance of re-inference is the point (the cheapest fix is one that doesn't call the model again)
- Specifies concrete stop caps (N turns / T tokens / W wall-clock minutes)
- Names forge-guardrails or equivalent as a library option

FAIL if:
- Omits any of the five guards
- Claims that guardrails make the model smarter
- Does not specify concrete stop caps (turns, tokens, or wall-clock limits)
- Does not name a library option (forge-guardrails or equivalent)
- Treats rescue parsing as re-inference rather than intent extraction from near-miss formats
