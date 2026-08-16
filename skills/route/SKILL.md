---
name: route
description: "Route each task to the cheapest model and effort that can pass its gate, escalating on failure (small/local -> haiku -> sonnet -> opus; low -> medium -> high effort). Right-sizes ambiguous tasks and prefers local small-dense models for narrow work. Trigger: which model, route this task, pick a model, escalate model, model tier, right-size this task."
user-invocable: true
---

# /route — Model & Effort Router

You are an **orchestrator** deciding which model and effort level runs a task. The principle across every talk: **owners run cheap, gatekeepers run expensive, and you escalate only when the gate says you must.** Implementation can run on the cheapest model that passes; code review and verdicts run on the strongest.

## The Ladder

```
LOCAL small-dense  →  cheap cloud (haiku)  →  mid (sonnet)  →  strong (opus)
low effort         →  medium effort        →  high effort
```

Start at the lowest rung a task can plausibly clear. Escalate one rung on each gate failure. Never start at the top "to be safe" — that is how a fleet burns its budget.

## Phase 1: CLASSIFY THE TASK

Score the task on three axes (read the `CONTRACT-*.md` if present):

1. **Ambiguity** — Small dense/local models need low ambiguity. "Write a unit test for *this specific function*" is narrow; "write tests for the app" is not. High ambiguity → right-size first (Phase 2) or route up.
2. **Complexity** — reasoning depth, number of interacting parts, novel vs boilerplate.
3. **Stakes** — blast radius if it's silently wrong (auth, payments, migrations, prompt-integrity → treat as high; internal formatting → low).

Map to a starting rung:

| Profile | Owner start | Effort |
|---------|-------------|--------|
| Narrow + low-stakes + boilerplate | local small-dense or haiku | low |
| Moderate complexity, well-specified | haiku → sonnet | medium |
| High complexity or novel reasoning | sonnet | medium/high |
| High stakes OR gatekeeper/verdict role | opus | high |

## Phase 2: RIGHT-SIZE BEFORE ROUTING UP

Before escalating an ambiguous task to a bigger model, try shrinking the ambiguity — it's cheaper. Rewrite the task into the narrowest specific form, or decompose it into narrow subtasks a small model can each complete. A right-sized task on a cheap model often beats a vague task on an expensive one. If it still can't be made narrow, route up.

## Phase 3: RUN, GATE, ESCALATE

```
owner (current rung) implements
      → run the gate (see /gate) FIRSTHAND
      → pass? hand to /verdict
      → fail? escalate ONE rung (model up, or effort up) and retry
```

**Escalation logic:**
- Gate fails on cheap model twice with no progress → bump model one rung.
- Output is low-quality junk (churn, no real attempt) → bump effort (low→medium→high) before bumping model.
- Track it: log `{task, rung, effort, attempts, gate_result, est_cost}` so the ladder is auditable.
- Cap total escalations (default 3 rungs). If opus/high still fails the gate → escalate to human; the contract may be wrong, not the model.

## Phase 4: LOCAL & COST NOTES

- **Local small-dense** (self-hosted) is effectively free per token — prefer it for narrow, high-volume, low-stakes work. Pair with `/survive` so the loop tolerates the smaller model's slips.
- Rotate paid subscriptions/subsidies for the cloud rungs; record which provider/model won each task class so routing improves over time.
- **Never route the verdict down.** The gatekeeper (`/verdict`) runs at the top rung regardless of what the owner used — a cheap judge defeats the point.

## Output

Report, one line per decision:

> "Task [id]: start local/haiku@low → gate fail → sonnet@medium → gate pass. Est cost $X. Verdict on opus."

## Handoff

- **`/survive`** — wraps the owner loop so a cheap/local model actually finishes.
- **`/verdict`** — always runs at the top rung; never trusts the owner's model or claim.
- **`/observe`** — records `$/run` and pass-rate per rung so routing is data-driven, not vibes.

> Verify-before-use: confirm which local runtime / model ids are actually available in this environment before routing work to "local small-dense" — do not assume a model is installed.
