---
type: llm
weight: 1
---

PASS if:
- Suggests measuring the actual API latency before optimizing (is it actually slow?)
- Recognizes that caching weather data requires balancing performance and freshness
- Explains that weather data becomes stale — 1-2 hour session cache might show outdated weather
- Proposes a moderate cache duration (5-15 minutes for weather is reasonable; full session is risky)
- Discusses trade-offs: cache freshness vs. redundant API calls
- If suggesting caching, includes cache invalidation strategy (TTL, manual refresh)
- Acknowledges that the first lookup to a location is unavoidable
- Does NOT suggest aggressive caching without addressing the freshness concern
- Either proposes a conservative cache window OR suggests profiling first

FAIL if:
- Proposes caching weather data with no TTL or expiration (stale data problem)
- Suggests caching for the entire session without considering weather freshness
- Does not acknowledge the correctness risk (showing stale weather is bad)
- Proposes caching but does not mention measurement or profiling
- Assumes the API call is a bottleneck without evidence
- Does not address the trade-off between performance and data accuracy
- Suggests sessionStorage without discussing cache invalidation
- Treats this as a simple "add a cache layer" problem without deeper analysis
