# Domain Candidate-Generation Agent Prompt

Dispatch one subagent per domain, in parallel. Substitute `[DOMAIN]` and `[TARGET_COUNT]` before sending.

---

**Goal:** Generate `[TARGET_COUNT]` candidate search queries in the domain **[DOMAIN]** where someone is trying to get a task done and a small software tool could do it for them.

**Inputs:** the domain name only. Everything else you find yourself.

## What qualifies as a candidate

Problem-intent queries — someone with a task, looking for a way to finish it. The shapes that qualify:

- `how to [task]`
- `[task] tool`, `[X] calculator`, `[X] converter`, `[X] generator`
- `[X] template`, `[X] checker`, `[X] tracker`, `[X] validator`
- `free [X] online`, `app for [X]`, `best way to [X]`
- `[X] without [annoyance]` — "without signing up", "without watermark", "offline"
- Questions asked repeatedly that a tool would answer better than an article
- Long-tail niche queries: specific professions, regulations, file formats, regional or non-US needs

## What is disqualified

- **Navigational and brand queries.** "gmail login", "youtube". High volume, zero unmet need.
- **News and entertainment.** Traffic without a task.
- **Broad categories.** "file conversion", "project management", "budgeting app". These cannot be verified or scoped. If your candidate could be a whole company, narrow it until it could be a weekend.
- **Queries already answered by a single AI chat turn** with no file handling, persistence, or integration. Flag these; the orchestrator's kill gate will confirm.

## Method

Use live search. Do not generate from memory alone — model priors about search behavior are stale and about which tools exist are staler.

1. **Google autocomplete patterns.** Seed with the domain plus each query shape above and record what completes.
2. **"People also ask" boxes.** These are literal transcripts of repeated questions.
3. **Reddit, Quora, and niche forums.** Search specifically for `"is there a tool that"`, `"does anyone know an app"`, `"I built a spreadsheet to"` plus the domain. A spreadsheet someone built by hand is a product that does not exist yet.
4. **Google Trends** for direction, not magnitude. Trends gives relative interest, never absolute volume — do not convert one into the other.
5. **Complaint mining.** App Store and Play reviews of adjacent tools, filtered to 1-3 stars. The feature everyone asks for and nobody ships is a candidate.

## Return format

A JSON array. One object per candidate. No prose outside the array.

```json
[
  {
    "query": "convert heic to pdf windows without uploading",
    "domain": "[DOMAIN]",
    "intent": "transactional",
    "volume_hint": 12000,
    "volume_basis": "autocomplete depth + 4 comparable converter keywords; Trends flat-to-rising",
    "confidence": "Estimated",
    "trend": "rising",
    "why_a_tool": "Privacy-conscious users refuse browser upload tools; needs local processing",
    "evidence_urls": ["https://reddit.com/..."],
    "suspected_incumbents": ["cloudconvert.com", "Windows Photos app"]
  }
]
```

Field rules:

- `volume_hint` — integer monthly searches. **If you did not measure it, you must still provide your basis in `volume_basis` and set `confidence` to `Estimated` or `Rough guess`.** Never label an inference as `Data`.
- `volume_basis` — the actual reasoning. "Comparable keyword X is known at ~20k and this is narrower" is a basis. "Seems popular" is not.
- `confidence` — `Estimated` when you triangulated from comparables or Trends. `Rough guess` when you are reasoning from first principles with no comparable found. These two are not interchangeable and the final report distinguishes them.
- `evidence_urls` — at least one real URL where you saw a human express this need. A candidate with no evidence URL will be weighted down.
- `suspected_incumbents` — your best guess at who already does this. **Do not verify it.** A later phase verifies supply properly; guessing here just tells that phase where to look first.

## Constraints

- Prefer narrow and specific over broad and large. A query you can fully scope beats a category you cannot.
- Do not score or rank. The orchestrator does that with data you do not have.
- Do not pad to hit the count. Ten real candidates beat fifteen with five invented.
- Do not research supply depth. That is Phase 5 and duplicating it wastes the run's budget.

**Voice for prose narration:** terse fragments, dropped articles where order stays clear, one fact stated once. Queries, URLs, numbers, and JSON always exact and complete. Full plain sentences for caveats and for anything you could not verify.
