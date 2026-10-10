---
type: llm
weight: 1
---

PASS if:
- Recognizes "supervise workers" as babysit trigger despite lowercase/informal tone and spacing
- Reply includes discovery and assessment reasoning (the same phases as the formal trigger case)
- Matches worker count and progress accurately
- Reply shows the atomic write pattern (heredoc to .NUDGE.md.tmp, then `mv`) for any NUDGE.md content it includes
- Console report shows timestamp, tick count (N/24 for 2-hour limit), and problem summaries

FAIL if:
- Fails to recognize trigger due to informal tone or spacing
- Skips discovery or assessment reasoning due to casual phrasing
- Produces inaccurate worker count or progress assessment
- Does not show the atomic write pattern for any included NUDGE.md content
- Console report missing timestamp, tick count, or problem summaries
