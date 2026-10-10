---
type: llm
weight: 1
---

PASS if:
- Identifies the pattern as N+1 query problem (1 parent query + N child queries per item)
- Proposes batch-fetching all members in a single query using `.in()` or similar
- Shows code that fetches all unique assignedMemberIds at once, then maps results
- Explains that this reduces 51 queries to 2 queries (1 for tasks, 1 for members in batch)
- Demonstrates how to map batch results back to tasks (groupBy or similar)
- Correctly associates the optimization with "batch queries" or "eliminated N+1"

FAIL if:
- Does not recognize the N+1 pattern
- Proposes caching or other optimizations without addressing the loop structure
- Suggests batch-fetching but shows incorrect SQL syntax or logic
- Does not reduce the actual number of queries
- Only parallelizes the N queries without batching them (still N+1, just concurrent)
- Misses that member lookup is the bottleneck in this specific code
