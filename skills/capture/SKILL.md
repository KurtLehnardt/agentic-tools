---
name: capture
description: "Turn a failure — a bug, a bad output, a prod incident, a verdict FAIL — into a minimal, reproducible eval level added permanently to the suite, so the same failure can never silently return. Builds the eval flywheel. Trigger: capture this failure, add a regression eval, this bug came back, turn this into an eval, failure to level, lock in this fix, reproduce this failure."
user-invocable: true
---

# /capture — Failure → Reproducible Eval Level

You are an **orchestrator** running the eval flywheel: **every failure becomes a reproducible level.** A "level" is a small, named, permanent eval that reproduces one specific failure and asserts the correct behavior. Once captured, that failure mode is fenced forever — it either stays fixed or the suite goes red.

This is how an eval suite compounds: you don't design it up front, you *grow* it by mining real failures — bad outputs, prod incidents, `/verdict` FAILs, security near-misses, model regressions.

## Phase 1: REPRODUCE

Take the failure (a `|||VERDICT|||` FAIL, a bug report, a logged bad output, a session transcript). Dispatch a **general-purpose** subagent to reduce it to the smallest input that still triggers it:

```
Subagent: Task tool, subagent_type="general-purpose"
Prompt: Reproduce and minimize this failure.
        Failure: [DESCRIPTION / TRANSCRIPT / FAILING OUTPUT]
        Produce:
        - The minimal input/state that triggers it (strip everything non-essential)
        - The observed wrong behavior (exact values)
        - The correct expected behavior (exact values)
        - Confirm the repro is deterministic; if flaky, capture the seed/conditions.
```

If it can't be reproduced deterministically, say so — a non-reproducible level is worse than none. Record it as a monitored signal (`/observe`) instead.

## Phase 2: PROMOTE TO A LEVEL

Add the repro to the suite as a permanent, named eval. Match the project's existing eval/test format (e.g. `skills/ship/evals/evals.json`-style records, or the framework in use):

- **Name** it after the failure mode: `checkout-empty-cart-nan`, `injection-egress-via-webhook`.
- **Assert the corrected behavior** — the level fails today (bug present) and passes once fixed.
- **Tag** it with source (`prod-incident`, `verdict-fail`, `model-regression`, `security`) and the model/rung it was seen on.
- If the failure was a stub sneaking past a gate, register the stub as a **negative fixture** so `/gate` stays stub-proof.

## Phase 3: WIRE IT IN

- Add the level to the gate that `/build` and `/verdict` run, so it's checked every cycle.
- Group related levels into a growing benchmark for that surface — this is your project-specific benchmark ("build your own; choose the metrics you care about"), not a generic public one.
- Record which models pass/fail the new level (feeds `/route`).

## Output

Report, one line:

> "Captured: `checkout-empty-cart-nan` (source: verdict-fail). Level is red on current code, green after fix. Added to gate + regression benchmark."

## Handoff

- **`/gate`** — the level joins the executable gate; negative fixtures keep it stub-proof.
- **`/observe`** — non-reproducible failures become monitored signals instead of levels.
- **`/route`** — pass/fail-per-model on the new level informs which rung can own similar work.

## Rule

**A bug is not fixed until it's a level.** A fix without a captured level is a fix that will silently regress the next time a model touches that code.
