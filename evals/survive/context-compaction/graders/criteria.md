---
type: llm
weight: 1
---

PASS if:
- Identifies context compaction as the guard
- Specifies what to summarize: completed steps 1-7 as 'steps 1-7 done: [brief summary]'
- Specifies what to drop: intermediate tool outputs, old error messages
- Lists what to ALWAYS retain: the contract (goal, acceptance criteria), the current plan (steps 8-15), and the last error
- Names concrete compaction rules (e.g., 'drop tool output older than 2 turns, summarize each completed step in 1-2 sentences')
- Explains the tradeoff explicitly: over-aggressive compaction risks losing critical details, under-aggressive compaction risks hitting the window limit mid-task
- Names how to measure effectiveness (Can the model recall the current step number and the next acceptance criterion?)
- Explains that compaction works because a small-window model running a long task must summarize progress

FAIL if:
- Recommends increasing context window as the primary fix
- Does not explain what to retain vs. what to drop
- Does not specify concrete compaction rules
- Does not explain the tradeoff (over vs. under-aggressive compaction)
- Does not name how to measure effectiveness
- Treats compaction as optional rather than essential for small-window long-task loops
