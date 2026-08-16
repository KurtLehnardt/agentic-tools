---
name: contract
description: "Turn a task into a declarative contract — objective/intent plus machine-checkable acceptance criteria and a stub-proof gate. Refuses prompt-as-wish and imperative pseudocode. Trigger: write a contract, define the contract, spec this task, contract for, declarative spec, acceptance criteria for."
user-invocable: true
---

# /contract — Declarative Work Contract

You are an **orchestrator** producing the one artifact the whole fleet builds against: a **contract**. A contract is *declarative* — it states the objective and how success is measured, and nothing about how to implement it. It is the alignment step. Owners DO, gatekeepers DOUBT — and both work from the same contract.

A contract is NOT a prompt and NOT a design:

| Form | What it is | Why it fails |
|------|-----------|--------------|
| **Prompt** (`"make the checkout fast and nice"`) | A wish | The agent has to guess your intent and shortcuts to something plausible |
| **Design** (`"add a Redis cache in checkout.ts, then loop over items…"`) | Imperative pseudocode | Locks in an implementation before anyone knows it's the right one; the agent can't improve on it |
| **Contract** (declarative) | Objective + acceptance criteria | States intent and the definition of done; leaves the *how* to the owner |

## What This Skill Produces

A **contract** saved as `CONTRACT-[task-name].md`:

1. **Objective / Intent** — one paragraph. What outcome, and *why* it matters. The intent line is what a gatekeeper checks "letter vs intent" against.
2. **Acceptance Criteria** — a numbered list, each criterion **machine-checkable**: an assertion, a command that exits 0/1, a metric with a threshold, an eval that scores pass/fail. No adjectives ("fast", "clean") without a number attached.
3. **The Gate** — the single executable check that decides done. It must be **stub-proof**: a hollow implementation that returns hardcoded/empty values must FAIL it. (Hand this section to `/gate` to make it real.)
4. **Out of Scope** — 3+ things explicitly NOT in this contract. Prevents scope creep and pity features.
5. **Owner / Gatekeeper split** — who builds (cheap model, per `/route`) and who judges (expensive model, per `/verdict`). The verdict and the accountability stay human — an agent acts *for* you within limits, it does not pretend to *be* you.

## Phase 1: EXTRACT INTENT

If a PRD exists (`PRD-*.md` from `/idea`), read it and pull the relevant slice. Otherwise interrogate the raw request. Dispatch a **general-purpose** subagent:

```
Subagent: Task tool, subagent_type="general-purpose"
Prompt: You are turning a request into a DECLARATIVE contract. Do not design an
        implementation. Do not restate the request as a wish.

        Request / PRD slice: [INPUT]

        Produce:
        - Objective/Intent (one paragraph, includes WHY)
        - Acceptance Criteria (numbered; each MUST be machine-checkable —
          a command, an assertion, a metric+threshold, or a scored eval)
        - Out of Scope (3+ items)

        Rules:
        - Reject any criterion you cannot verify with a command or a number.
        - If the request is a wish ("make it good"), convert each vague word
          into a measurable criterion or list it as an open question.
        - Do NOT specify files, functions, data structures, or algorithms.
```

## Phase 2: STUB-PROOF THE GATE

For each acceptance criterion, ask the killer question:

> **Could a stub pass this?** (A function that returns `[]`, `true`, or a hardcoded fixture.)

If yes, the criterion is a wish in disguise — tighten it until only real work passes. This is the seed for `/gate`, which will *prove* stub-resistance by actually writing a stub and confirming failure.

**Gate logic (self-check):**
- Every criterion has a check that is command-runnable or scoreable → proceed.
- Any criterion is subjective or stub-passable → REVISE Phase 1 for that criterion. Max 3 cycles, then flag the unresolved ones as human decisions.

## Phase 3: OUTPUT

Save `CONTRACT-[task-name].md`. Report to human, one line:

> "Contract ready: [task-name]. N acceptance criteria, all machine-checkable. Gate is stub-proof (verify with `/gate`). Owner tier suggested: [tier]."

## Handoff

The contract is the input artifact for:
- **`/gate`** — turns the Gate section into an executable, stub-proofed check
- **`/route`** — reads complexity/ambiguity to pick the owner model tier
- **`/build`** — implements against the acceptance criteria
- **`/verdict`** — validates the deliverable claim-by-claim against these criteria

## Never Hand to an Agent

Agents help *draft* the contract. Humans set the target. Two things are never delegated:
- **The outcome** — what we're building and how success is measured.
- **The accountability** — there is no "the AI did it." The contract has a human owner.
