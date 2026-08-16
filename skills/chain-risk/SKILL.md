---
name: chain-risk
description: "Compute compounding-error risk for a multi-step or multi-agent pipeline — per-step success rate raised to step count — and show where cumulative reliability falls below target, so you know where to place gates and checkpoints. Trigger: chain risk, compounding error, how reliable is this pipeline, where do I add gates, reliability math, why does my agent fail over long runs, step count risk."
user-invocable: true
---

# /chain-risk — Compounding-Error Analysis

You are an **orchestrator** doing the reliability math that justifies where gates go. The uncomfortable arithmetic behind every long agent run:

> A step that succeeds **99.9%** of the time, run **50** times, succeeds end-to-end only **~95%** of the time. At **95%** per step, 50 steps in a row succeed only **~7.7%** of the time — i.e. it *fails* more often than not.

`p_success(pipeline) = p_step ^ n_steps` (independent steps). Small per-step slips compound into near-certain failure over a long chain. This is the quantitative reason for `/gate` and `/verdict`: **checkpoints reset the chain.**

## Phase 1: MODEL THE PIPELINE

Enumerate the steps / tool calls / agent hops in the flow (read the plan, the `/build` decomposition, or the harness trace). For each step estimate a success probability (from `/observe` history if available — real `err%` beats guessing; otherwise use a conservative default and label it an assumption).

## Phase 2: COMPUTE

```
Ungated:   p_end = Π p_step_i              (all steps must succeed in a row)
Uniform:   p_end = p^n                     (quick estimate at rate p over n steps)
```

Report the curve — how end-to-end success decays as `n` grows — and the **break-even step count** where `p_end` drops below the target (e.g. 90%).

| p_step | n=10 | n=25 | n=50 |
|--------|------|------|------|
| 0.999  | 99.0% | 97.5% | 95.1% |
| 0.99   | 90.4% | 77.8% | 60.5% |
| 0.95   | 59.9% | 27.7% | 7.7% |

## Phase 3: PLACE THE GATES

A gate/checkpoint that catches and corrects a failure **resets the chain** for the steps after it. Segment the pipeline so no ungated run exceeds the break-even length:

```
p_end ≈ Π ( p_segment_i )   where each segment is short enough that
                             p_step ^ segment_len stays above target,
                             and a gate corrects before the next segment.
```

Recommend:
- **Where** to insert gates (after which steps) to keep every segment above target reliability.
- **Which** steps carry the most risk (lowest `p_step` × highest downstream fan-out) — harden or route those up first (`/route`).
- Whether the chain is simply **too long** — decompose it (`/build`) so segments are independently gated and, where possible, parallel rather than serial.

## Output

Report, concise:

> "Pipeline: 40 steps @ ~0.97 → ungated end-to-end ~29%. Break-even (90%) at 3 steps. Recommend gates after steps 3, 9, 18, 27 (4 segments, each ≥90%). Riskiest: step 22 (0.90, feeds 6 downstream) — route up."

## Handoff

- **`/gate`** — build the checkpoints at the recommended positions.
- **`/verdict`** — the terminal gate; also resets trust between owner and merge.
- **`/observe`** — supplies real per-step `err%` so the model is measured, not assumed.
- **`/route`** — escalate the model on the riskiest steps to raise their `p_step`.

## Note

Independence is an approximation — correlated failures (one bad assumption poisoning many steps) can be worse than `p^n` predicts. Treat the number as a floor on how many gates you need, not a ceiling.
