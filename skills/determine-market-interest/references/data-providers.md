# Keyword Data Providers — Setup and Costs

`/determine-market-interest` runs with or without a provider. Without one, every volume figure is labeled `Estimated` and the report says so in its first line. With one, figures are labeled `Data`.

All specs below were verified against official vendor documentation on 2026-10-07. Where a field could not be verified first-hand, it is marked and the script handles it defensively rather than assuming.

Check what is configured at any time, free:

```bash
node skills/determine-market-interest/scripts/keyword-volume.mjs --check-keys
```

This runs only zero-cost quota probes. It never spends credits.

---

## DataForSEO — recommended

Cheapest by a wide margin, and the only one of the three returning absolute monthly history.

```bash
export DATAFORSEO_LOGIN="your-api-login"
export DATAFORSEO_PASSWORD="your-api-password"

# optional
export DATAFORSEO_LOCATION_CODE="2840"   # required for any --country other than us
export DATAFORSEO_LANGUAGE_CODE="en"     # defaults to en
```

Only `location_code` 2840 (US) was verified against the docs, so any other market requires `DATAFORSEO_LOCATION_CODE` explicitly. The script errors with the locations-doc URL rather than guessing a code, because a wrong location code silently returns volumes for the wrong country.

Get credentials at https://app.dataforseo.com/api-access. **These are an API login and an auto-generated API password — not your account login and not your account password.** Using the account password will fail authentication.

- Endpoint: `POST https://api.dataforseo.com/v3/keywords_data/google_ads/search_volume/live`
- Auth: HTTP Basic
- Batch: up to **1000 keywords per task**
- Volume: `tasks[].result[].search_volume`, a 12-month average
- History: `monthly_searches[]` as `{year, month, search_volume}` — **absolute numbers, so trend is computed rather than inferred**
- **Cost: $0.09 per task regardless of keyword count.** A 60-candidate run is one task. Nine cents.
- Rate limit: 12 requests/minute on live endpoints
- The real charge is echoed in the response `cost` field, and the script reports it rather than predicting it

Docs: https://docs.dataforseo.com/v3/keywords_data/google_ads/search_volume/live/

---

## Semrush

```bash
export SEMRUSH_API_KEY="your-key"
```

Requires a Business subscription plus purchased API units.

- Endpoint: `GET https://api.semrush.com/?type=phrase_these` (batch) or `type=phrase_this` (single)
- Auth: `key=` **query parameter**, not a header
- Batch: up to **100 keywords**, joined by `;`
- Response: **semicolon-delimited CSV**, not JSON
- Volume: column `Nq`
- Trend: column `Td` — 12 comma-separated **relative** values 0.00-1.00. Direction only. These are not volumes and must never be reported as volumes.
- Cost: 10 API units per returned line. **USD per unit is not published** — Semrush sells unit packages and quotes price through sales, so the script reports spend in units and states that the dollar conversion is unknown.
- Rate limit: 10 requests/second, 10 concurrent
- Free balance check: `GET http://www.semrush.com/users/countapiunits.html?key=<KEY>`

**Licensing constraint, enforced in the script:** Semrush's API usage restrictions prohibit caching their data beyond one month without written consent. The cache therefore applies a hard 30-day TTL to Semrush rows specifically, while other providers get 90 days. Do not raise that TTL without obtaining written consent from Semrush first.

Docs: https://developer.semrush.com/api/v3/analytics/keyword-reports/

---

## Ahrefs

```bash
export AHREFS_API_KEY="your-key"
```

- Endpoint: `GET https://api.ahrefs.com/v3/keywords-explorer/overview`
- Auth: `Authorization: Bearer`
- Required params: `select` (comma-separated columns) and `country` (two-letter code)
- Volume: `volume`, a 12-month average. Also `volume_monthly` (latest month) and `global_volume`.
- Cost: API units, allowance by plan tier — Lite 200k/mo, Standard 800k, Advanced 2M. **USD per unit is not published.**
- Rate limit: 60 requests/minute
- Free smoke test, 0 units: a request whose `keywords` is only `ahrefs`
- Free quota check, 0 units: `GET https://api.ahrefs.com/v3/subscription-info/limits-and-usage`

**Two documented gaps, handled defensively in the script rather than guessed:**

1. `volume_monthly_history` is typed `array<object>` and the official reference renders its example as `[{}]` with no inner keys. The script inspects keys at runtime instead of assuming `{date, volume}`, and sets `trend: null` with a stderr warning if it cannot confidently map them.
2. The units-cost formula could not be loaded first-hand — every direct fetch of `docs.ahrefs.com/en/api/docs/limits-consumption` returns HTTP 404, while `/en/api/reference/*` pages load fine. The script therefore reports the actual `x-api-units-cost-total-actual` response header rather than predicting spend from a formula that could not be read directly.

Docs: https://docs.ahrefs.com/en/api/reference/keywords-explorer/get-overview

---

## No Provider — CSV Export

The zero-cost path to `Data`-labeled figures. Export from Keyword Planner, Ahrefs, or Semrush in the browser and pass the file:

```bash
/determine-market-interest --keywords ~/Downloads/keyword-export.csv
```

The script auto-detects the column layout of all three vendors' standard exports. Note the export's date — keyword exports age, and a six-month-old export is not current demand.

---

## No Provider At All

`/determine-market-interest` still runs end to end. Every volume figure is labeled `Estimated` or `Rough guess`, the report's first line states the data mode, and the methods note explains that ordinal ranking is more trustworthy than absolute figures.

This is a supported mode, not a degraded failure. The honest version of an estimate is genuinely useful for ranking opportunities against each other. What is not acceptable is an estimate presented as measurement, which is why the labeling law in `demand-estimation.md` is absolute.

---

## Script Exit Codes

The orchestrator should branch on these rather than parsing stderr.

| Code | Meaning | What the skill should do |
|---|---|---|
| 0 | Success | Proceed with `Data`-labeled volumes |
| 1 | Usage or configuration error | Report it; a wrong `--country` without a location code lands here |
| 2 | Operator declined the spend prompt | Fall back to estimated mode, do not retry |
| 3 | No provider configured | Fall back to estimated mode — **this is a normal path, not a failure** |
| 3 | `--check-keys` found nothing configured | Same — the probe succeeded and reported an empty result |
| 4 | Estimated spend exceeded `--max-spend` | Report the figure to the user and ask before passing `--yes` |
| 5 | Completed, but at least one chunk failed | Use what returned; affected rows are `NoData` |

Exit 3 is the expected outcome for a user who has never configured a key, so treat it as a branch rather than an error. Exit 4 means money was deliberately not spent — never auto-retry it with `--yes`, because that spends the user's money on a threshold they set specifically to prevent it.

## Spend Safety

Three guards, all enforced in the script rather than left to the caller:

- **Preflight.** Estimated spend is printed and checked against `--max-spend` (default $1.00) before any paid request. Only DataForSEO publishes a USD price, so the numeric gate can only bind there. `--max-spend 0` additionally refuses all Semrush and Ahrefs calls, on the reasoning that an unpublished price cannot be shown to be zero.
- **Actual-cost readback.** DataForSEO's charge is read from the response `cost` field and Ahrefs' from the `x-api-units-cost-total-actual` header, then reported on stderr. The script reports what was actually billed rather than what it predicted.
- **Dedup and cache.** Duplicate queries collapse to one lookup before billing. Only `Data` rows are cached, so a `NoData` result always retries on the next run instead of caching a gap.

## Not Yet Implemented

Researched partially or not at all, left out of v1 deliberately:

- **Google Ads API `KeywordPlanIdeaService`** — free in principle, but needs an approved developer token and a full OAuth flow. High setup burden for the same data DataForSEO resells at nine cents a task.
- **SerpApi** — would help supply assessment by returning organic SERPs programmatically, but it cannot classify a result as a working tool versus an article, and that classification is the signal Phase 5 actually needs. Humans and agents reading pages remains the method.
- **Google Trends** — no official API. Unofficial libraries exist and break regularly. Agents read Trends pages directly in Tier 3 estimation instead.
