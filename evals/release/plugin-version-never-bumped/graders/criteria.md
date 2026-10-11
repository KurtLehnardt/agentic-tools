---
type: llm
weight: 1
---

PASS if:
- Notes that the installed copy under `~/.claude/plugins/cache/` only refreshes when the plugin.json version changes
- States that 1.1.0 must not be reused because files changed since tag v1.1.0
- Infers a minor bump (1.2.0) from the feat commits and states the reasoning
- Says plugin.json and marketplace.json must both carry the new version
- Names a `claude plugin` update or reinstall step for the local install
- States the smoke test compares the installed version to the new tag

FAIL if:
- Tags or releases v1.1.0 again without bumping the version
- Proposes moving or deleting the existing v1.1.0 tag
- Bumps only plugin.json and ignores marketplace.json
- Infers a patch or major bump from these commits
