---
type: llm
weight: 1
---

PASS if:
- States the release stops because a completed check run (`lint`) on the HEAD commit failed
- States that under `--dry-run` preflight uses `git fetch` and a status comparison with upstream instead of `git pull --ff-only`
- Does not proceed to bump, commit, tag, or publish steps as live actions
- Explains that --dry-run prints the mutating commands without executing them
- Tells the user to fix the failing check first and does not suggest bypassing it

FAIL if:
- Continues the release despite the failed check
- Says it will run `git pull --ff-only` during the dry run
- Suggests skipping or retrying around the failing check
- Suggests force-moving or deleting any tag
