---
type: llm
weight: 1
---

PASS if:
- States that with no prior tag this is the first release
- Uses the current manifest version 0.3.0 as is, so the tag is v0.3.0
- Says release notes cover the whole commit history since there is no earlier tag
- Does not try to infer a bump from commits since a last tag

FAIL if:
- Bumps to 0.3.1 or 0.4.0
- Fails or stops because `git describe` finds no tag
- Proposes diffing against a previous tag that does not exist
