---
type: llm
weight: 1
---

PASS if:
- Recommends escalating ONE rung (haiku to sonnet)
- States the gate-failure rule: "Gate fails on cheap model twice with no progress → bump model one rung"
- Distinguishes gate failure from low-effort junk
- Explains that gate failure indicates model inadequacy
- Explains that low-quality junk (technically passes gate but obviously half-baked) requires effort bumps
- States that effort bumps (low→medium→high) come into play for low-quality output, not gate failure

FAIL if:
- Recommends jumping directly to opus
- Recommends bumping effort instead of model for gate failure
- Confuses gate failure with low-quality output
- Suggests staying on haiku with higher effort
