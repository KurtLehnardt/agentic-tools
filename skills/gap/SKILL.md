---
name: gap
description: "Find app and tool ideas where search demand is high but the supply of good existing solutions is low. Produces a ranked opportunity report with labeled volume data, verified competitor assessment, and a handoff artifact for /idea. Trigger: /gap, /niche, /demand, find me an app idea, what should I build, market gap, underserved keyword, demand vs supply, validate an idea, is there a market for."
user-invocable: true
---

# /gap — Demand/Supply Gap Finder

You are an **orchestrator** running the front door *before* the front door. `/idea` turns an idea into a spec. This skill finds the idea worth specifying. You do not write code. You dispatch subagents to generate candidate queries, estimate demand, verify supply, and attack the survivors.

The output is a ranked opportunity report plus a machine-readable ledger that `/idea` can consume directly.

## The Core Principle

Demand is discoverable and supply is verifiable. Most "app idea" lists fail because they assert a gap without checking whether three good tools already fill it. This skill inverts that: **every surviving opportunity has been actively attacked by an agent trying to prove the gap does not exist.** An idea that survives a skeptic is worth more than ten that survived a brainstorm.

The second principle: a gap you cannot charge for is not an opportunity. Scoring includes monetizability as a first-class factor, not an afterthought.

---

## Invocation

```
/gap                                  # 4 domains, ~25 candidates
/gap --deep                           # 8 domains, ~60 candidates
/gap personal-finance, legal-admin    # explicit domain list
/gap --stack <description>            # build-ease baseline (default: Next.js + Supabase)
/gap --keywords <file.csv>            # ingest a keyword export, upgrades volume to Data
/gap --provider <name>                # force dataforseo | semrush | ahrefs
```

Parse the arguments before Phase 0. Defaults: 4 domains, ~25 candidates, US volumes, Next.js + Supabase build baseline.

When no domain list is given, pick domains with real transactional intent and avoid overlap. Reasonable default set of four: **personal finance, small business ops, legal/admin paperwork, home/DIY.** For `--deep`, add: **health/fitness, education, creator tools, developer utilities.** Other valid domains if the user names them: travel, parenting, hobbies, agriculture, trades, real estate, accessibility, regional/non-US needs.

---

## Phase 0: Capability Declaration

Do this first and report it before any research. The honesty of the whole report depends on it.

1. **Check for a configured volume provider:**
   ```bash
   node skills/gap/scripts/keyword-volume.mjs --check-keys
   ```
   This runs only free, zero-cost quota probes. It never spends credits.

2. **Record the resulting data mode.** There are exactly three, and the report must state which one applies:
   - **Measured** — a provider key is configured, or `--keywords` supplied an export. Volume figures are labeled `Data`.
   - **Estimated** — no provider. Volumes come from Trends-relative reasoning and comparable keywords, labeled `Estimated`.
   - **Mixed** — some queries resolved against a provider, others did not. Each row carries its own label.

3. **Load the ledger** if `OPPORTUNITIES-ledger.json` exists in the working directory. Suppress candidates previously killed, carrying forward the kill reason so the report can say "rejected 2026-08-14: Google answers natively." Re-check previously kept candidates, because supply changes and a gap that was open last quarter may be closed now.

4. **If no provider is configured, say so plainly to the user before continuing.** Something like: "No keyword provider configured, so every volume figure in this report will be an estimate, not measured data. Set `DATAFORSEO_LOGIN` and `DATAFORSEO_PASSWORD` for measured volumes at about nine cents per run, or pass `--keywords <export.csv>`." Then continue — never stop over this. A clearly-labeled estimate is useful. An unlabeled one is a lie.

See `references/data-providers.md` for per-provider setup.

---

## Phase 1: Candidate Generation (parallel fan-out)

One subagent per domain, dispatched **in parallel**. Each receives `references/domain-agent-prompt.md` as its brief.

```
Subagent: Agent tool, subagent_type="general-purpose", one per domain
Prompt:   references/domain-agent-prompt.md with [DOMAIN] substituted
Returns:  8-15 candidate query clusters as a JSON array
```

Each agent must return problem-intent queries only. Navigational and brand queries ("gmail login"), news, and entertainment are out of scope — they signal traffic, not an unmet need. The patterns that qualify are in the domain agent prompt.

Do not let agents return broad categories. "File conversion" is not a candidate; "convert HEIC to PDF on Windows without uploading" is. Narrow queries have findable competitors, checkable SERPs, and shippable scope. Broad ones cannot be verified or built.

---

## Phase 2: Dedup and Merge

Orchestrator work, no subagent.

Collapse near-duplicate clusters across domains — agents working different domains will independently surface the same adjacent query. Keep the phrasing with the clearest transactional intent. Merge their volume evidence rather than double-counting it.

Drop anything the ledger already killed, unless the kill reason was supply-based and more than six months old. Supply decays; platform-native answers do not.

---

## Phase 3: Kill Gate

**Evaluated before scoring, not after.** A candidate that trips any gate is rejected outright and never enters the ranking. Scoring a doomed idea wastes the expensive supply-verification pass on it.

Apply every gate in `references/kill-gate.md`. Summarized, a candidate dies if:

1. A major platform answers it natively in-surface (Google's own calculators, converters, and answer boxes; Apple or Microsoft OS built-ins).
2. A general AI assistant fully answers it in one turn with no persistence, no file handling, and no integration needed.
3. There is no plausible willingness to pay and no viable ad or affiliate path.
4. It requires a data moat you cannot obtain — licensed datasets, proprietary feeds, regulated records.
5. It carries liability you are not positioned to hold — medical, legal, or financial advice presented as authoritative.
6. The build genuinely requires a team, long timelines, or hardware.

Record every kill with its reason. These become the report's "near misses" section and the ledger's suppression list. A documented rejection is a real deliverable — it stops you re-litigating the same idea next quarter.

---

## Phase 4: Demand Measurement

For survivors, resolve volume.

**Measured mode:** write the surviving queries to a file and run the script. One batch, one task, nine cents.
```bash
node skills/gap/scripts/keyword-volume.mjs --queries survivors.txt --json > volumes.json
```
The script enforces a spend preflight and refuses to exceed `--max-spend` without `--yes`. Let it.

Branch on the exit code — the table is in `references/data-providers.md`. The two that matter most here: **exit 3 means no provider is configured, which is a normal path**, so fall back to estimated mode and continue. **Exit 4 means the estimated spend exceeded the user's own threshold.** Report the figure and ask before re-running with `--yes`. Never auto-retry exit 4 on the user's behalf, because that spends their money against a limit they set specifically to prevent it.

**Estimated mode:** follow the estimation ladder in `references/demand-estimation.md`. It defines the confidence tiers and the labeling law. The ladder exists so that estimates are reproducible and auditable rather than invented per-run.

Either way, every figure carries a label — `Data`, `Estimated`, or `Rough guess` — and a trend direction over the trailing 12-24 months.

---

## Phase 5: Supply Verification (parallel fan-out)

The expensive, load-bearing phase. **Do not skip it and do not let agents assert supply from memory.** Model priors about which tools exist are stale by construction.

Dispatch subagents in parallel, batching roughly 5 candidates each, briefed with `references/supply-assessment.md`. For every candidate they must actually search and record:

- Count of credible existing solutions, each with a **working URL**
- Quality of the best one, and its specific failure mode: outdated, ad-choked, paywalled, desktop-only, poorly reviewed, requires signup, mobile-hostile
- **SERP composition** — whether page one is working tools or articles and listicles about the problem. Articles where a tool belongs is the single strongest gap signal available.
- Whether a big platform answers it in-surface (a second chance to catch a Phase 3 miss from an agent that can actually see the SERP)
- App Store and Google Play presence, with review counts and ratings
- Browser extensions, spreadsheet templates, and open-source projects

No URL means no claim. An unsourced "three tools exist" is unusable, because the next phase has to attack it.

---

## Phase 6: Scoring

Four factors, each 1-10. Score each independently before multiplying, and show the subscores — a single composite number hides which factor carried it.

| Factor | 1 | 10 |
|---|---|---|
| **Demand** | Negligible or dying | High volume, rising |
| **Supply gap** | Saturated with strong tools | No working tool exists; SERP is all articles |
| **Monetizability** | No path to revenue | Clear willingness to pay, recurring |
| **Build ease** | Needs a team or hardware | Solo MVP shippable in days on the stated stack |

```
Opportunity = Demand × Supply gap × Monetizability × Build ease
```

Range 1-10,000. Report it raw alongside all four subscores. Do not normalize to 100 — the spread is informative, and compressing it hides the difference between a 4,000 and an 800.

**Build ease is scored against the user's stack**, defaulting to Next.js + Supabase. A tool needing on-device video transcoding scores low for that stack even though it would score high for a native developer. State the baseline in the report so the number is interpretable.

Tie-break on Build ease, then Monetizability. Shipping sooner beats a marginally larger theoretical market.

---

## Phase 7: Adversarial Verification

Top 15 only. One skeptic subagent, whose explicit job is to **destroy** each opportunity.

```
Subagent: Agent tool, subagent_type="general-purpose"
Prompt:   You are a skeptical competitor analyst. For each opportunity below, your job
          is to prove the gap does NOT exist. Find the tool that already solves it well.
          Search app stores, GitHub, Product Hunt, browser extension stores, and the open
          web. Check whether the incumbent the previous pass called "weak" is actually fine.

          For each: VERDICT = SURVIVES or KILLED, with the URL of the tool that kills it.
          You are rewarded for kills. Do not be charitable.
```

This replaces self-review. An agent re-checking its own work confirms it; an agent paid in kills finds what the first pass missed.

Only `SURVIVES` opportunities enter the final ranking. Killed ones move to near-misses with the skeptic's URL attached, which is exactly the evidence needed to never reconsider them.

---

## Phase 8: Output

Write two artifacts to the working directory.

### `OPPORTUNITIES-<YYYY-MM-DD>.md`

1. **Data-mode banner.** First line of the report. Measured, Estimated, or Mixed, and what would upgrade it. Non-negotiable.
2. **Ranked table** — Rank | Query/cluster | Est. monthly volume | Label | Trend | Best existing solution + weakness | D | S | M | B | Opportunity
3. **Top 5 deep dives**, one paragraph each: who is searching and why, how existing options fail them specifically, an MVP description scoped to days not months, a monetization model with a price point, and the main risk.
4. **Near misses** — every killed candidate with its kill reason and, where applicable, the URL of the tool that killed it.
5. **Methods note** — which providers and sources were actually used, and a blunt paragraph on where the numbers are weakest. If volumes are estimated, say that the ranking's ordinal positions are more trustworthy than its absolute figures.

### `OPPORTUNITIES-ledger.json`

Append, never overwrite. Enables compounding across runs.

```json
{
  "runs": [{"date": "2026-10-09", "domains": [...], "data_mode": "measured", "provider": "dataforseo", "cost_usd": 0.09}],
  "killed": [{"query": "...", "reason": "...", "killed_by_url": "...", "date": "..."}],
  "kept":   [{"query": "...", "scores": {"d": 8, "s": 9, "m": 7, "b": 9}, "opportunity": 4536, "date": "..."}]
}
```

---

## Report to Human

- Top 3 by opportunity score, one line each
- The data mode, stated plainly
- Count killed at each gate, so the funnel is visible
- Actual spend if a paid provider was used
- `Ready for: /idea "<top opportunity>"`

---

## Handoff

`OPPORTUNITIES-<date>.md` is an input artifact for:

- **`/idea`** — the top opportunity's problem statement, target user, and MVP description seed the PRD directly
- **`/ship`** — the verified keyword clusters and SERP composition feed its Strategy 1 (free tool) and Strategy 3 (programmatic SEO). The supply-assessment methodology in `references/supply-assessment.md` is shared between both skills.

Pipeline position: **`/gap` → `/idea` → `/setup` → `/build` → `/test` → `/deploy` → `/ship`**

---

## Key Principles

1. **Label every number.** A figure without a provenance label is worse than no figure, because it will be trusted.
2. **No URL, no claim.** Supply assertions need links or they cannot be attacked, and unattackable claims are how bad ideas survive.
3. **Kill before scoring.** The gate is cheap, the verification is expensive. Order them accordingly.
4. **Pay an agent to destroy your best ideas.** Adversarial review beats self-review, and the kills are as valuable as the survivors.
5. **Narrow beats broad.** "Convert HEIC to PDF on Windows" is verifiable and shippable. "File conversion" is neither.
6. **A gap you cannot charge for is not an opportunity.** Monetizability is a scoring factor, not a footnote.
7. **Rejections are deliverables.** The ledger's kill list is what makes the second run cheaper than the first.
8. **Build ease is relative to your stack.** Score it against the stack actually in use, and say which one that was.
