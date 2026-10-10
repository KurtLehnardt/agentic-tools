# Kill Gate

Runs in Phase 3, **before** scoring and before the expensive supply-verification pass. Any gate tripped means rejection — no score, no further research spend.

Order matters. The gate is cheap, verification is not.

## Gate 1 — Platform-Native

**Kill if** Google, Apple, or Microsoft answers this in-surface or ships it in the OS.

Google answers natively: unit conversion, currency, basic and scientific math, timers, stopwatches, translation, time zones, dictionary, weather, flight status, package tracking, tip and percentage math, color pickers, sunrise/sunset.

OS built-ins: Preview and Photos (image conversion, PDF merge, markup), Shortcuts and Automator (automation), Notes (scanning, OCR), Calculator, Files, Clock.

You cannot out-distribute a default. The default needs no discovery, no install, and no trust.

**Survives if** the native answer is strictly partial in a way users complain about — single-file only when they need batch, online-only when they need offline, no export, no persistence. Cite the complaint; do not assert it.

## Gate 2 — One-Turn LLM

**Kill if** a general AI assistant fully resolves this in a single turn, with no file handling, no persistence, no integration, and no repetition.

Examples that die here: "how to write a resignation letter", "explain X", "give me a workout plan", "name ideas for Y". A chat window already does these better than a form-based tool would, and that substitution is permanent.

**Survives if** any of these hold:
- **Files.** Real input or output artifacts: parse a PDF, batch-process images, emit a valid .ics or .csv.
- **Persistence.** The value is in state across sessions — tracking, history, reminders, versioning.
- **Integration.** Pulls live or authenticated data: a bank feed, a calendar, an API, a scraped source.
- **Determinism.** The answer must be exactly right every time — tax math, regulatory thresholds, unit-critical engineering.
- **Repetition.** Run weekly, so a purpose-built UI beats re-prompting.
- **Non-technical users.** The audience will not adopt a chat interface, however capable.

This gate is the most commonly mis-applied, in both directions. Be concrete about which escape clause applies and why, rather than waving at one.

## Gate 3 — No Monetization Path

**Kill if** there is no plausible route to revenue.

Check, in order of preference: subscription, one-time purchase, usage-based pricing, freemium with a real paid tier, affiliate where the adjacent purchase is genuinely high-value, ads where volume is large enough to matter.

Warning signs: no advertisers bidding on a commercial-intent query; the audience is structurally unable to pay (students, hobbyists at zero budget); the task is so infrequent that no subscription survives; free, well-maintained open-source alternatives set the price at zero.

**Survives if** you can name the payer, the price point, and the moment they decide to pay. If you cannot name all three, the gate holds.

A high-demand, wide-open gap with no payer is a hobby project. That may be fine — but it is not what this skill is searching for, and mixing the two corrupts the ranking.

## Gate 4 — Unobtainable Data Moat

**Kill if** it requires data you cannot get: licensed datasets (MLS, credit bureau, medical coding), proprietary feeds behind enterprise contracts, regulated records, or a cold-start network where the product is worthless until thousands of users arrive simultaneously.

**Survives if** the data is public, scrapeable within terms of service, user-supplied, or available through an affordable API. Confirm pricing before clearing this gate — "there's an API" is not the same as "the API is affordable at MVP scale."

## Gate 5 — Liability

**Kill if** shipping it means presenting medical, legal, or financial advice as authoritative, handling regulated data without the corresponding compliance posture (HIPAA, PCI, FERPA), or taking on consequences a solo operator cannot carry.

**Survives if** it is a calculator or organizer the professional uses rather than an advisor the layperson relies on, or if a disclaimer genuinely covers the use case. Be honest here rather than optimistic. A tool that produces a number someone files with a government agency carries real exposure even with a disclaimer attached, and that exposure lands on you personally.

## Gate 6 — Not Solo-Shippable

**Kill if** an MVP genuinely needs a team, many months, hardware, physical logistics, or per-market regulatory approval.

**Survives if** a credible thin slice ships in days to a few weeks on the user's stack. Scope the slice explicitly — most "too big" ideas contain a shippable wedge, and finding that wedge is the job. Reject only when no wedge exists.

## Recording Kills

Every kill is a deliverable. Record all four fields:

```json
{"query": "...", "gate": 2, "reason": "ChatGPT writes this in one turn; no file, state, or integration",
 "date": "2026-10-09"}
```

These populate the report's near-misses section and the ledger's suppression list. A documented rejection is what stops the next run re-deriving the same dead end — which is the mechanism that makes run two cheaper than run one.

## Re-Examination Policy

Not all kills are permanent, and the ledger must reflect that.

- **Gates 1, 2, 5 — permanent.** Platform defaults, assistant capability, and liability do not swing back in your favor.
- **Gates 3, 4, 6 — expire after 6 months.** API pricing drops, data opens up, and your own capability grows. Re-examine rather than suppressing forever.
- **Supply-based kills from Phase 7 — expire after 6 months.** Incumbents are abandoned and acquired constantly. The tool that killed an idea last spring may be dead now, so re-check the URL before suppressing again.
