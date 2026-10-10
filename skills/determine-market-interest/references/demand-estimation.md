# Demand Estimation — Ladder and Labeling Law

Two jobs: produce a defensible monthly volume figure, and make its provenance impossible to misread.

## The Labeling Law

Every volume figure in every artifact carries exactly one label. No exceptions, no unlabeled numbers anywhere in the report.

| Label | Means | Allowed when |
|---|---|---|
| `Data` | Measured by a keyword provider or read from a user-supplied export | A provider returned a row, or `--keywords` supplied it |
| `Estimated` | Triangulated from comparable keywords or Trends-relative reasoning | A documented basis exists in `volume_basis` |
| `Rough guess` | First-principles reasoning, no comparable found | Nothing better was available |
| `NoData` | The provider was asked and returned no row | Provider ran, query absent from results |

`NoData` is not zero. A provider returning no row means low-or-unmeasured volume, which is a different fact from measured-zero demand, and the report must not collapse them. Keep these rows visible rather than dropping them — a genuinely novel query can be real demand that the provider has not indexed.

**Never present an estimate as measured data.** This is the rule the whole skill's credibility rests on. If the report's banner says Estimated, the reader calibrates correctly and the report stays useful. If an estimate is dressed as data, every downstream decision inherits a false precision, and the user may spend weeks building against a number that was invented.

## Tier 1 — Measured

A provider is configured. Run the script, use `search_volume` or equivalent, label `Data`.

```bash
node skills/determine-market-interest/scripts/keyword-volume.mjs --queries survivors.txt --json > volumes.json
```

DataForSEO returns an absolute 12-month `monthly_searches` history, so trend direction is computed, not inferred. Prefer it when available.

Cost is nine cents for a thousand keywords in one task. For any serious run, configure a key — it is cheaper than the time spent reasoning about estimates, and it converts the entire report from Estimated to Measured.

## Tier 2 — User Export

`--keywords <file.csv>` from Keyword Planner, Ahrefs, or Semrush. Label `Data`. Note the export's date in the methods section, because keyword exports age and a six-month-old export is not current demand.

## Tier 3 — Comparable Triangulation

No provider. Find a keyword whose volume is publicly known or widely cited, establish the relationship, scale.

1. Identify a comparable with a known or well-cited volume.
2. Pull both into Google Trends and read the ratio of relative interest.
3. Scale the known absolute by that ratio.
4. Record all of it in `volume_basis`.

Trends gives relative interest only. The ratio is usable; the raw Trends number is not a volume and must never be reported as one.

Label `Estimated`. Expect to be wrong by a factor of two or three. State that in the methods note.

## Tier 4 — Structural Inference

No comparable found. Reason from observable structure, and be explicit that this is the weakest tier.

Signals that correlate with real volume:

- **Autocomplete depth.** Google suggesting many specific completions means many people finish that phrase.
- **"People also ask" presence.** Google only populates it for repeated questions.
- **Paid ads on the SERP.** Advertisers bidding is the strongest available free signal that volume converts to money. No ads on a commercial-intent query is a monetizability warning.
- **Forum thread volume and recency.** Many recent threads means an active unmet need.
- **Result count.** Weak signal, easily inflated. Use it last.

Label `Rough guess`. Order-of-magnitude only — say "low thousands" rather than "4,200", because a fabricated specific number invites a trust it has not earned.

## Trend Direction

Required on every candidate, over the trailing 12-24 months. One of `rising`, `flat`, `declining`, or `null`.

- **Measured:** compare the mean of the trailing 3 months against the same 3 months a year earlier. Over +15% is rising, under -15% is declining, between is flat.
- **Semrush `Td`:** 12 relative values 0.00-1.00. Direction only. These are not volumes and converting them to volumes is wrong.
- **Estimated:** read the Trends curve and say so.

Trend outranks raw volume for ranking purposes. A rising 5,000 beats a declining 20,000, because you are building for the market that will exist when you ship, not the one that existed when it peaked.

## Where These Numbers Are Weakest

The methods note must own all of this:

- Estimated volumes are routinely off by 2-3x. Ordinal ranking is far more trustworthy than absolute figures.
- Keyword tools report the head phrasing and under-report long-tail variants, so narrow queries look smaller than the real demand behind them.
- Provider volumes are 12-month averages and flatten seasonality. A tax tool looks modest year-round and is enormous in March.
- Trends is relative, normalized, and sampled. It supports no absolute claim whatsoever.
- US-only figures miss international demand, which for some niches is the larger half.
