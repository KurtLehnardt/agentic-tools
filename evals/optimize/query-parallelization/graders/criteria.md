---
type: llm
weight: 1
---

PASS if:
- Identifies the sequential await pattern as a bottleneck that blocks parallel execution
- Proposes using `Promise.all()` or similar pattern to run queries in parallel
- Shows code using `const [events, members, taskCount, completedCount] = await Promise.all([...])` or equivalent
- Recognizes that none of these queries depend on each other's results
- Correctly explains that parallel execution reduces total load time from ~400-800ms to ~100-200ms
- Estimates or explains the expected performance impact (N sequential queries → 1 concurrent batch)

FAIL if:
- Does not recognize the sequential await pattern as a performance issue
- Suggests keeping the queries sequential
- Proposes Promise.all but shows incorrect syntax or structure
- Adds Promise.all but wraps only some queries (incomplete parallelization)
- Misses that these specific queries are independent
- Confuses this with other optimization patterns (caching, indexing)
- Does not show concrete code changes
