---
type: llm
weight: 1
---

PASS if:
- Recognizes "supervise workers" as babysit trigger despite lowercase/informal tone and spacing
- Executes discovery and assessment phases (same as formal trigger case)
- Matches worker count and progress accurately
- Uses atomic write pattern (.NUDGE.md.tmp → mv) for NUDGE.md files
- Console report shows timestamp, tick count (N/24 for 2-hour limit), and problem summaries

FAIL if:
- Fails to recognize trigger due to informal tone or spacing
- Skips discovery or assessment phases due to casual phrasing
- Produces inaccurate worker count or progress assessment
- Does not use atomic write pattern for NUDGE.md
- Console report missing timestamp, tick count, or problem summaries
