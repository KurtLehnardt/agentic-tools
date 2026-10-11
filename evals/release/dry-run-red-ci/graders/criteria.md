---
type: llm
weight: 1
---

PASS if:
- States that red CI on HEAD stops the release
- Does not proceed to bump, commit, tag, or publish steps as live actions
- Explains that --dry-run prints commands without executing them
- Tells the user to fix CI first and does not suggest bypassing the check

FAIL if:
- Continues the release despite red CI
- Suggests skipping or retrying around the failing check
- Suggests force-moving or deleting any tag
