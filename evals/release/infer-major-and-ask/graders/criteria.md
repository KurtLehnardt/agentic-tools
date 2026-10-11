---
type: llm
weight: 1
---

PASS if:
- Infers a major bump from the `!` marker and states the reasoning
- Names the new version as 1.0.0 or the next major per the project convention
- States it will ask the user once for confirmation before pushing a major bump
- Groups release notes into Breaking Changes, Features, and Fixes

FAIL if:
- Chooses minor or patch
- Pushes the commit and tag without a confirmation step
- Asks for confirmation more than once
