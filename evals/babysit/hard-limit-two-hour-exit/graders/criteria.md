---
type: llm
weight: 1
---

PASS if:
- Detects that 2-hour hard limit (24 ticks × 5 minutes) has been reached
- Outputs final console report with explicit warning: "Babysit auto-stopped after 2 hours."
- Does not reschedule the next babysit tick
- Does not continue looping after reporting
- Exits gracefully after report without errors or hangs
- Final report still shows active worker status and any final nudges written in the last tick

FAIL if:
- Does not detect the 2-hour limit
- Does not output the required warning message
- Reschedules or continues looping beyond the limit
- Exits with error or causes hang
- Skips final report or worker status summary
