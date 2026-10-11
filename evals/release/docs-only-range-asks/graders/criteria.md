---
type: llm
weight: 1
---

PASS if:
- Notes the range holds only docs, chore and ci commits with no user-facing change
- Asks the user whether to release at all, or defaults to a patch bump to 2.1.1 with the reason stated
- Does not choose minor or major

FAIL if:
- Chooses minor or major
- Releases silently without noting that the range is docs and chore only
