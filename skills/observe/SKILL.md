---
name: observe
description: "Instrument an agent or LLM feature with structured spans per model and tool call, tracking the four reliability signals — P95 latency, cost per run, tool error rate, and eval pass rate — so runs can be replayed, alerted, and scored. Start with one critical use case. Trigger: add observability, instrument the agent, LLM ops, track cost and latency, structured spans, monitor the pipeline, llmops, four signals."
user-invocable: true
---

# /observe — Agent Observability

You are an **orchestrator** making an agent legible. **If you can't see it, you can't fix it.** Emit a structured span per model call and per tool call so every run can be replayed, alerted on, and scored. Two disciplines, kept distinct:

- **Monitoring** (the *what*, software side) — log inputs/outputs, cost, latency, errors; catch security and misalignment issues; track usage.
- **Evaluating** (the *why*, data-science side) — score behavior against benchmarks you own. Handled by `/gate` + `/capture`; this skill feeds it the `eval pass rate` signal.

## The Four Signals

Track these per model span and per tool span — they are the signals that move reliability:

1. **P95 latency** — per model and per tool span (p95, not mean — the tail is what stalls the loop).
2. **$/run** — token cost, input and output, per trace.
3. **err%** — tool error rate (executor failures, malformed responses, rescued vs unrescued — see `/survive`).
4. **eval pass rate** — scored against your levels (`/capture`) and gates (`/gate`).

## Phase 1: START WITH ONE

Do not instrument everything. Pick the **single most valuable / most critical** LLM use case in the codebase and build observability around just it. Prove value on one trace, then expand. (Ask: which one feature, if it silently degraded, would hurt most?)

## Phase 2: EMIT SPANS

Wrap each model call and tool call to emit a structured span:

```json
{
  "trace_id": "...", "span_id": "...", "parent_id": "...",
  "kind": "model" | "tool",
  "name": "opus | search_web | run_tests",
  "input": "...", "output": "...",
  "tokens_in": 0, "tokens_out": 0, "cost_usd": 0.0,
  "latency_ms": 0, "error": null,
  "eval": {"gate": "checkout", "passed": true, "score": 0.94}
}
```

Spans nest into a trace you can **replay** (re-drive the run), **alert** on (p95/err%/cost thresholds), and **score** (eval pass rate over time).

## Phase 3: WIRE A BACKEND

Route spans to an LLM-ops backend. Three flavors — pick one and don't overthink it:
- **Open source, self-host** — e.g. Opik, Langfuse, MLflow (good default to start).
- **Managed** — a hosted vendor.
- **Roll your own** — a spans table + a dashboard, if requirements are narrow.

Pair scoring with **Promptfoo** (or equivalent) for the eval pass-rate signal against your `/capture` levels.

## Phase 4: OBSERVE FOR SAFETY

Observability isn't only reliability — it surfaces attacks and misalignment: an unexpected egress destination, a tool call outside the allow-list, a prompt that mutated. Feed anomalies to `/sandbox` (containment) and `/constitution` (prompt-integrity). **Observability is the what; evaluation is the why** — together they build trust: transparency, accuracy, calibration, alignment.

## Output

Report, one line:

> "Instrumented [feature]: spans emitting to [backend]. Signals live — p95 [x]ms, $[y]/run, err [z]%, eval-pass [w]%. Alerts set on p95 and err%."

## Handoff

- **`/chain-risk`** — consumes real per-step `err%` instead of guessed rates.
- **`/route`** — consumes `$/run` and pass-rate per model rung.
- **`/capture`** — non-reproducible anomalies become monitored signals here rather than eval levels.

> Verified Aug 2026, all current and production-real: **Langfuse** (MIT, most widely adopted open-source LLM tracing; now under ClickHouse), **Opik** (Comet ML — trace logging + eval scoring + prompt optimization), **MLflow** (broad ML + LLM tracing), and **Promptfoo** (evals, CI gates, red-teaming). All treat the trace as the primary object and attach eval scores to spans. Confirm the specific SDK version for whichever you adopt.
