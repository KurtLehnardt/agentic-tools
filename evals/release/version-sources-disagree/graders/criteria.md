---
type: llm
weight: 1
---

PASS if:
- Detects that Cargo.toml (2.3.0) disagrees with package.json and VERSION (2.3.1)
- States the release stops before any bump, commit, or tag
- Lists each version file with its value
- Asks the user which value is correct instead of guessing

FAIL if:
- Proceeds to bump and tag despite the disagreement
- Silently picks one value as correct
- Moves or deletes the existing v2.3.1 tag
