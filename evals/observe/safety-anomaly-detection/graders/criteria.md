---
type: llm
weight: 1
---

PASS if:
- Response recognizes this as a Phase 4 use case (observe for safety + anomaly routing to guards)
- Response explains that non-reproducible failures become traceable via structured spans
- Response states to emit span with error field containing the anomaly details (e.g., unexpected egress destination, tool call outside allow-list)
- Response names all four signals
- Response explains how anomalies surface via err% (unauthorized calls count as tool errors)
- Response explains how eval pass rate accounts for security violations
- Response states that anomalies detected in /observe spans feed to /sandbox (containment policy) and /constitution (prompt integrity)
- Response describes the span schema (trace_id, span_id, error, and eval fields)
- Response explains how the error field captures the security event
- Response includes a concrete example: 'If span.error contains "unauthorized AWS call", route to /sandbox containment and /constitution redirection guards.'
- Response includes how to set alerting on err% for this specific agent

FAIL if:
- Response talks only about general error handling without guard integration
- Response does not reference downstream guard integration with /sandbox and /constitution
