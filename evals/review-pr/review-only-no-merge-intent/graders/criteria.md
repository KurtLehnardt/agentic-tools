---
type: llm
weight: 1
---

PASS if:
- States the request has no merge intent: no merge, land or ship wording and no `--merge`
- Ends the run by reporting the PR as ready to merge
- Says the user can re-run with `--merge` to merge it
- Lists the skipped nit in the final report

FAIL if:
- Plans to run `gh pr merge` on PR 214
- Asks the user whether to merge instead of stopping at ready to merge
- Assigns a numeric score to the PR
