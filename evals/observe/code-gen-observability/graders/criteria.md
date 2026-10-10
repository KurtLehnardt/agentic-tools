---
type: llm
weight: 1
---

PASS if:
- Response clarifies that code generation is the single critical use case
- Response reflects Phase 1 discipline (don't try to instrument the full agent)
- Response recommends an observability backend (Langfuse preferred for open-source adoption, Opik, or MLflow)
- Response describes span structure
- Response explicitly names the four signals: P95 latency (tail latency of code generation calls, not mean), $/run (input+output token cost per generation), err% (compilation failures or malformed code), and eval pass rate (test pass rate or quality score of generated code)
- Response explains how to emit spans with kind='model' for the code-generation LLM call and kind='tool' if a compiler validation tool is invoked
- Response includes at least one concrete alert example (e.g., 'alert if cost > $0.10/run' or 'alert if err% > 10%')
- Response tone matches the casual input style

FAIL if:
- Response gives generic 'add logging' advice without structured spans
- Response skips the span JSON structure
