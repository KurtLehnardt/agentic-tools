---
name: gate
description: "Generate an executable gate for a contract or task, then prove it is stub-proof by writing a hollow stub and confirming the gate rejects it. If a stub can pass your eval, the eval is the bug. Trigger: build a gate, make the gate, stub-proof, executable acceptance test, gate for this contract, prove the eval works."
user-invocable: true
---

# /gate — Stub-Proof Gate Builder

You are an **orchestrator** turning acceptance criteria into an **executable gate** — the check that decides definition-of-done. The gate's defining property is that **a stub cannot pass it**. The talk's rule is absolute:

> **If a stub can pass your eval, your eval is the bug.**

A gate that a hollow implementation satisfies gives false green — the most expensive failure in an overnight fleet, because you wake up trusting it.

## What This Skill Produces

1. **The gate** — a runnable artifact: a test suite, an eval script, or a command that exits `0` (pass) / non-zero (fail). Deterministic where possible; for LLM-scored gates, a rubric + threshold.
2. **The stub-proof** — evidence that the gate actually rejects a stub (see Phase 2). This is the meta-test that keeps the gate honest.
3. **A run command** — a single line `/verdict` and `/build` can invoke to re-run it firsthand.

## Phase 1: BUILD THE GATE

Read the `CONTRACT-*.md` (or the criteria the user supplies). Dispatch a **general-purpose** subagent per criterion cluster:

```
Subagent: Task tool, subagent_type="general-purpose"
Prompt: Write an executable gate for these acceptance criteria:
        [CRITERIA]

        Requirements:
        - Every criterion maps to at least one assertion that can FAIL.
        - Assert real behavior and real values — not that a function was called,
          not that a file exists, not that output is non-empty.
        - Include boundary and negative cases (empty, malformed, over-limit).
        - Exit 0 only if all assertions pass; non-zero otherwise.
        - Reuse the project's existing test framework and conventions.
        Output the gate file(s) and the exact command to run them.
```

## Phase 2: STUB-PROOF IT (the point of this skill)

Now attack your own gate. Dispatch an **adversarial** subagent to write the laziest possible passing attempt:

```
Subagent: Task tool, subagent_type="general-purpose"
Prompt: You are an adversary. Here is a gate: [GATE].
        Write the most hollow implementation that could plausibly be submitted
        as "done" — return hardcoded values, empty collections, echo the input,
        no-op side effects, fixtures that match the happy-path assertion.
        Your goal: make the gate pass WITHOUT doing the real work.
        Report whether the gate passed your stub, and exactly which assertion
        (if any) let the stub through.
```

**Gate-on-the-gate logic:**
- Stub **FAILS** the gate → the gate is stub-proof. Record the failing assertion as evidence. Proceed to Phase 3.
- Stub **PASSES** the gate → **the eval is the bug.** Feed the passing stub back to Phase 1 and strengthen the assertions that let it through (assert values not calls, add negative cases, check invariants). Max 4 cycles, then escalate: "Cannot make this criterion stub-proof: [criterion]. It may be unobservable — needs a human decision."

Optionally record the stub as a permanent negative fixture via `/capture` so the gate can never silently regress into stub-passable.

## Phase 3: OUTPUT

Report, one line:

> "Gate ready: N assertions across M criteria. Stub-proof verified — hollow stub failed at `[assertion]`. Run with: `[command]`."

## Handoff

- **`/build`** wires the gate into the worker's self-review loop (worker cannot claim done until the gate is green).
- **`/verdict`** re-runs this exact gate firsthand — never trusting the owner's "it passed."
- **`/chain-risk`** uses gate placement to compute where pipeline reliability needs more checkpoints.

## Rules

- **Evidence, not say-so.** A gate is only real once you've watched it reject a stub.
- **Assert values, not calls.** "The function was invoked" is stub-passable; "the returned total equals 42 for this basket" is not.
- **Letter ≠ intent.** A gate enforces the letter. Where letter and intent can diverge, add an assertion that pins the intent, or route that judgment to `/verdict`.
