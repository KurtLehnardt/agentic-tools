---
type: llm
weight: 1
---

PASS if:
- Maps 'aren't nitpick' to `--min low` and says which value was chosen
- Maps 'rebuild the android app' to the `--then` action
- States the critic is opus at high or xhigh effort with a fresh read-only context
- Chooses squash as the merge method based on the repo convention and deletes the branch
- Says the `--then` action runs only after the merge succeeded
- Says the final report lists found, fixed, skipped findings and the merge SHA

FAIL if:
- Runs the android rebuild before the merge completes
- Merges with a method other than squash
- Treats nit findings as in scope for fixing
- Assigns a numeric score to the PR
