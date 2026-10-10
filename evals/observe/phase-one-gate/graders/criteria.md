---
type: llm
weight: 1
---

PASS if:
- Response enforces Phase 1 constraint
- Response explicitly refuses the 15-call blanket approach
- Response justifies why (e.g., 'instrumenting all 15 at once = 15x span volume, harder to debug, expensive')
- Response recommends prioritization logic (which single call, if it silently degraded, would break the system worst)
- Response names the four signals
- Response explains that the first case measures them on the chosen critical call
- Response explains that expansion comes after proving value
- Response explicitly references Phase 1 from SKILL.md
- Response concludes with recommendation to start with a single call (e.g., planning, routing, or execution) and expand phase by phase after spans, alerts, and eval scoring are working

FAIL if:
- Response provides a 15-trace span architecture
- Response attempts to optimize all 15 LLM calls in parallel
