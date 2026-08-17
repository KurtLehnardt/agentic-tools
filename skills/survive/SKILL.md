---
name: survive
description: "Wrap a worker loop so smaller or local models actually finish — response validation, rescue parsing, corrective nudges, step enforcement, and context compaction. The model proposes the next action; the harness makes the loop survivable. Trigger: make the loop survivable, harden the loop, worker keeps failing, wrap the agent loop, small model completion, forge-style loop."
user-invocable: true
---

# /survive — Survivable Worker Loop

You are an **orchestrator** hardening an agent loop so it completes even when the owner is a small or local model. The model's job is to **propose the next action**. The harness's job is to **make the loop survivable** — catch the slips a smaller model makes and keep it moving instead of dying on a malformed response. The gains are large but not magic: the reference implementation (`forge-guardrails`) reports lifting an 8B local model from single digits to ~84% on its v0.7.0 agentic eval suite, and Sonnet 4.6 from ~85% to ~98% — by catching mistakes, not by making the model smarter.

## The Five Guards

Wrap every owner iteration with these, in order:

1. **Response validation** — Before acting on the model's output, check it against the expected shape (valid JSON, a known tool name, required fields, a legal next step). Reject early; don't feed a malformed action to an executor.
2. **Rescue parsing** — When the response is *almost* right (fenced JSON with prose around it, a trailing comma, a near-miss tool name), extract the intent programmatically instead of re-inferring. **Rescue avoids paying for another inference** — the cheapest fix is the one that doesn't call the model again.
3. **Corrective retry nudges** — If validation and rescue both fail, retry with a *precise* nudge naming exactly what was wrong ("return only JSON matching this schema; you included prose"). **Precise nudges prevent blind retries** — never resend the same prompt and hope.
4. **Step / workflow enforcement** — Enforce the legal state machine. Block repeated actions, premature "done" claims, and out-of-order steps. A worker cannot skip the gate or declare complete before its acceptance criteria are green.
5. **Context compaction** — Keep the working context within the model's (often small) window: summarize completed steps, drop stale tool output, retain the contract, the plan, and the last error. Compaction is what lets a small-window model run a long task.

### Use the library or roll your own

The five guards are implemented by `forge-guardrails` (`pip install forge-guardrails`; [antoinezambelli/forge](https://github.com/antoinezambelli/forge)), which targets self-hosted backends (llama-server, Ollama, vLLM, llamafile) and the Anthropic API. Three entry points, pick per your loop:

- **`WorkflowRunner`** — it orchestrates the full agentic lifecycle for you.
- **`Guardrails`** facade — composable middleware to drop into your *own* loop (e.g. wrap a `/build` worker).
- **`python -m forge.proxy`** — an OpenAI-compatible proxy server; put the guards in front of any client with zero code change.

The guards below stand on their own if you'd rather hand-roll them; the library just saves you writing the rescue/compaction logic.

## Phase 1: WRAP THE LOOP

Identify the loop to harden (a `/build` ralph-worker, a local-model agent, an MCP tool loop). Insert the five guards around its `call model → run tool → append` cycle. The core loop shape stays:

```
build context (compacted) → validate proposed action → rescue if near-miss
   → enforce step legality → execute → append result → repeat or stop
```

Keep the **stop condition** explicit and hard: cap turns, tokens, and wall-clock so a confused loop can't spin forever (see `/observe` for the signals that reveal spinning).

## Phase 2: TUNE PER MODEL

- Smaller/local model → validate more strictly, compact more aggressively, keep steps tiny (pairs with `/route` right-sizing).
- Rescue rules are cheap insurance — add one every time you see a recurring near-miss format.
- Log each guard's fire-rate. If "corrective nudge" fires constantly on the same step, the *task* is too ambiguous — send it back to `/route` to right-size or escalate, don't just nudge harder.

## Phase 3: OUTPUT

Report, one line:

> "Loop wrapped: validation + rescue + nudge + step-enforce + compaction. Stop caps: N turns / T tokens / W min. Completion on [model]: X%."

## Handoff

- **`/route`** — decides which model runs inside the survivable loop and when to escalate.
- **`/build`** — the ralph-worker loop is a natural place to install these guards.
- **`/observe`** — spans reveal which guard fires most, i.e. where the loop is fragile.

> Verified Aug 2026: `forge-guardrails` is real ([antoinezambelli/forge](https://github.com/antoinezambelli/forge), results presented at CAIS 2026). Its exact terms: *response validation*, *rescue parsing*, *retry loop with error tracking*, *prerequisite enforcement & step-ordering* (multi-turn only), and *context compaction* (`ContextManager`, e.g. `TieredCompact`). Benchmark numbers are version-specific (v0.7.0 above) — re-check the repo, and pin the version.
