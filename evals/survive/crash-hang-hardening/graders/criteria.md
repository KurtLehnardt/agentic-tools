---
type: llm
weight: 1
---

PASS if:
- Parses two distinct failure modes: malformed responses and hanging loops
- Explains that response validation + rescue parsing handle malformed responses
- Explains that step/workflow enforcement prevents repeating the same action
- Explains that context compaction keeps the loop focused through long runs
- Names at least one concrete rescue rule (e.g., extract JSON between triple backticks, trim trailing commas)
- Recommends logging each guard's fire-rate to identify which guard is overloading
- Explicitly addresses the small context window by naming what to drop (stale tool output) vs. what to retain (contract, plan, last error)

FAIL if:
- Treats malformed responses and hanging loops as a single failure mode
- Recommends swapping to a larger model as the primary fix
- Does not name a concrete rescue rule
- Does not explain context compaction strategy
- Ignores the small context window constraint
- Does not recommend fire-rate logging for identifying guard overload
