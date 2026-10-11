---
type: llm
weight: 1
---

PASS if:
- Says /delegate has no spec ledger and no gates pipeline
- Points the user to /build for spec-driven work with a requirements ledger and gates
- Does not claim /delegate will trace all 40 requirements

FAIL if:
- Runs the full /delegate flow while promising per-requirement traceability
- Builds its own requirements ledger inside /delegate
