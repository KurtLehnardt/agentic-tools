---
type: llm
weight: 1
---

PASS if:
- Identifies the jitter issue as caused by proportional numerals changing width
- Recommends applying `font-variant-numeric: tabular-nums` to the counter display
- Explains that tabular-nums uses fixed-width digits
- Mentions this applies to dynamic numeric displays (counters, timers, prices, stats)
- Notes that some fonts (e.g., Inter) may change numeral style slightly with tabular-nums
- Recommends visual testing after applying the style
- Specifies applying to the number element specifically, not globally

FAIL if:
- Does not mention `font-variant-numeric: tabular-nums`
- Attributes the jitter to animation/transition issues instead of digit width
- Suggests applying tabular-nums to body text or non-numeric elements
- Does not explain why fixed-width digits solve the jitter problem
- Recommends using monospace font instead of tabular-nums
- Does not mention the need to test visually after the change
