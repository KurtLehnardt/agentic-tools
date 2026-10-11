---
type: llm
weight: 1
---

PASS if:
- States the 0.x rule makes the breaking change a minor bump
- Names the new version as 0.10.0
- States the reasoning with the commit that decided it
- States that moving to 1.0.0 only happens if the user asks for it

FAIL if:
- Chooses 1.0.0 or any major bump
- Chooses a patch bump
- Treats the release as needing the major-bump push confirmation
