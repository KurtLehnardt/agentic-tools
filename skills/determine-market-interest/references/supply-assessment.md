# Supply Assessment Protocol

How to determine whether good tools already solve a query. Shared methodology — `/determine-market-interest` uses it to find gaps, `/ship` uses it in reverse to position a known product against incumbents (Strategy 1, free tool; Strategy 3, programmatic SEO).

## The Rule

**No URL, no claim.** Every assertion about what exists needs a working link. Unsourced claims cannot be attacked by the adversarial pass, and unattackable claims are exactly how bad ideas survive to the top of a ranking.

Do not assess supply from memory. Model knowledge of which tools exist is stale by construction — tools launch, get acquired, and die continuously, and your training data has a cutoff the market does not respect.

## Surfaces to Check

All six, every candidate. Skipping one is how an incumbent gets missed.

1. **Open web.** Search the query itself, then the query plus `tool`, `online`, `free`, `calculator`, `generator`. Search as a user would, not as a researcher would.
2. **App Store and Google Play.** Record app name, rating, and review count. A 4.6 with 40,000 reviews is a wall. A 3.1 with 50 reviews is an opening.
3. **Browser extensions.** Chrome Web Store and Firefox Add-ons. Users often take the extension over the website, and an extension incumbent is invisible from a plain web search.
4. **GitHub.** An open-source CLI that solves it means the problem is solved for developers and open for everyone else. Note stars and last commit date — an archived repo is not live supply.
5. **Product Hunt.** Catches recent launches that have not earned SEO yet. These are the incumbents a web search misses.
6. **Spreadsheet templates.** A widely-shared Google Sheets or Excel template is proof of demand *and* proof that no software product captured it. This is one of the strongest signals in the entire protocol.

## SERP Composition — The Strongest Free Signal

Classify page one. Count results in each bucket:

- **Working tools** — you can complete the task on the page
- **Articles and listicles** — "7 best ways to…", "How to…" prose
- **Forum threads** — Reddit, Quora, Stack Exchange
- **Platform-native answers** — Google's own widget, calculator, or answer box

**A commercial-intent query whose page one is articles about the problem rather than tools that solve it is the clearest gap signal available.** It means search demand exists, Google has nothing better to rank, and content marketers noticed the traffic before product builders did.

The inverse is equally decisive: three or more working tools on page one means saturated, regardless of how weak any individual one looks.

No API can do this classification. SERP APIs return URLs and titles; whether a page is a working tool or an article about the problem requires opening it. Budget for that and do not pretend otherwise.

## Platform-Native Check

Does Google, Apple, or Microsoft already answer this in-surface?

Search the query and look for Google's own unit converter, calculator, timer, translator, color picker, or answer box. Check whether the OS ships it — Preview, Photos, Shortcuts, Calculator, Notes.

A platform-native answer is fatal and non-negotiable. You cannot out-distribute the default, because the default requires zero discovery. This duplicates the orchestrator's kill gate on purpose, because that gate runs on candidate text while this check runs against a SERP you can actually see.

## Quality Assessment of the Best Incumbent

Find the strongest existing solution and name its specific failure mode. "It's bad" is not a finding; these are:

- **Outdated** — last updated years ago, broken on current browsers or OS versions
- **Ad-choked** — the tool works but the experience is hostile
- **Paywalled too early** — the core job requires payment before any value is shown
- **Signup-gated** — email required before the user can try it
- **Desktop-only or mobile-hostile** — unusable where the need actually occurs
- **Poorly reviewed** — users specifically complain, and about what
- **Privacy-hostile** — uploads files to a server when local processing would do
- **Partial** — solves 70% and abandons the user at the hard part

If the best incumbent has none of these, say so plainly and score the supply gap low. Honest saturation findings are what make the rest of the report trustworthy, and an analyst who never finds a closed market is not looking.

## Return Format

```json
{
  "query": "...",
  "solution_count": 3,
  "solutions": [
    {"name": "CloudConvert", "url": "https://cloudconvert.com/heic-to-pdf",
     "type": "web", "quality": 7, "weaknesses": ["uploads files to server", "paywalled over 25/day"]}
  ],
  "serp_composition": {"tools": 2, "articles": 6, "forums": 1, "platform_native": 0},
  "platform_native": false,
  "platform_native_note": "Windows Photos exports HEIC to PDF but only one file at a time",
  "app_store": [{"name": "...", "rating": 3.2, "reviews": 48, "url": "..."}],
  "extensions": [], "github": [], "templates": [],
  "best_incumbent_quality": 7,
  "supply_gap_score": 6,
  "gap_thesis": "Batch and local-only processing is the unserved slice; incumbents are cloud-upload single-file"
}
```

`gap_thesis` is the load-bearing field. One sentence naming the specific unserved slice. If you cannot write it, there is no gap and the candidate should score low — a vague thesis means the analysis has not found anything real.

## Scoring Supply Gap, 1-10

| Score | Condition |
|---|---|
| 10 | No working tool exists anywhere; SERP is entirely articles and forums |
| 8-9 | One weak or abandoned tool; SERP mostly articles |
| 6-7 | Two or three tools, all with a named failure mode; a clear unserved slice |
| 4-5 | Several decent tools; differentiation possible but narrow |
| 2-3 | Strong, well-maintained, well-reviewed incumbents |
| 1 | Saturated, or answered platform-natively |
