---
type: llm
weight: 1
---

PASS if:
- Routes to local small-dense or haiku
- Routes to low effort
- Identifies the task as narrow (single function)
- Identifies the task as boilerplate (date parsing is well-defined)
- Identifies the task as low-stakes (internal tooling, not auth/payment)
- States that owners run cheap
- Distinguishes ownership from verdict roles

FAIL if:
- Recommends sonnet or opus
- Recommends medium or high effort
- Suggests over-engineering the task
