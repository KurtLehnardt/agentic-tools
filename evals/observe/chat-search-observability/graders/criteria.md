---
type: llm
weight: 1
---

PASS if:
- Response identifies the chat agent as the single critical use case
- Response recommends spans for both the search_web tool call and the summarization model call
- Response is disciplined to Phase 1 (no attempt to instrument both model and tool spans simultaneously)
- Response recommends a backend (Langfuse MIT, Opik, or MLflow) with justification
- Response shows or describes the span structure including trace_id, span_id, parent_id, kind, name, tokens_in, tokens_out, cost_usd, latency_ms, error, and eval fields
- Response explicitly names all four signals: P95 latency per search_web call, cost per run ($/run in tokens), tool error rate (err% for search failures), and eval pass rate (scored accuracy of summaries)
- Response confirms that spans will be replay-able and alert-able (e.g., alert if p95 > 3000ms or err% > 5%)

FAIL if:
- Response proposes instrumenting LLM features other than this chat agent before this one is proven
- Response omits the span schema
