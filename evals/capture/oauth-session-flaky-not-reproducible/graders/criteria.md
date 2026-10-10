---
type: llm
weight: 1
---

<!-- Doctrine 6 choice: the "let pushback alone pass" option. SKILL.md's own rule for a
     non-reproducible failure is to stop short of creating a level and route to /observe
     instead — there is no artifact to demand here, so this case is graded on the refusal
     and the reasoning behind it, not on any produced level. -->

PASS if:
- Reasons explicitly about reproducibility — directly or by describing a subagent-style investigation — and states the determination in the reply
- Recognizes the non-reproducible pattern ('sometimes works, sometimes doesn't')
- Determines the failure is NOT deterministically reproducible
- Explicitly refuses to create a permanent eval level for non-reproducible failures
- Recommends /observe instead of /capture
- Suggests monitoring signals such as 'oauth session creation failures', count per provider, or P50 latency
- Clearly communicates that non-reproducible failures are not level-ready and require structured observation

FAIL if:
- Creates a permanent eval level despite recognizing non-reproducibility
- Routes to a permanent eval level ('flaky' level or otherwise) instead of /observe
- Assumes the bug is reproducible just because it has been seen a handful of times
- Does not distinguish between non-reproducible issues and reproducible ones
- Fails to recommend /observe as the appropriate handling for flaky/intermittent issues
