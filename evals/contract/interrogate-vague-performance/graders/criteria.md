---
type: llm
weight: 1
---

PASS if:
- Asks all six clarifying questions: (1) Which queries? (all, or specific tables/operations); (2) Current baseline latency?; (3) Target latency and percentile (p50, p95, p99)?; (4) Load context (QPS)?; (5) Which execution environment (dev, staging, prod)?; (6) What constitutes success (query time, throughput, resource utilization)?
- Produces a CONTRACT-* file
- Contains partial contract skeleton with sections labeled
- Records all six clarifying questions in an OPEN QUESTIONS section
- Notes "Cannot finalize Gate until these specifics are locked" or equivalent statement
- Marks Gate section as unresolvable without thresholds
- Does not invent latency numbers, percentiles, or targets not provided
- Does not use generic criteria like 'faster' or 'optimized' without quantification
- Flags each question as a human decision that must be made
- Explains that specifics must be supplied before finalizing acceptance criteria

FAIL if:
- Fails to ask any of the six clarifying questions
- Does not produce a CONTRACT-* file
- Invents latency numbers, percentiles, or load targets not provided by user
- Uses vague acceptance criteria like 'faster', 'optimized', 'improved'
- Does not record open questions or human decisions
- Does not mark Gate as unresolvable
- Makes assumptions about query scope, environment, or load profile
- Provides concrete Gate section without noting missing thresholds
- Treats the vague request as complete and final
