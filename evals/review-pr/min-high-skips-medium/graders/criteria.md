---
type: llm
weight: 1
---

PASS if:
- Fixes only findings (1) and (2), the critical and high ones, because `--min high` was given
- Lists findings (3) medium and (4) nit as skipped and says they appear in the final report
- Dispatches a fix subagent and names opus for the critical finding
- Says a fresh critic re-reviews after the fix and re-verifies each prior finding firsthand
- Says CI is checked with `gh pr checks --watch` before any merge
- States that the request has no merge intent (no merge, land or ship wording and no `--merge`), so the run ends by reporting the PR as ready to merge instead of merging
- States severity is a category, not a numeric score

FAIL if:
- Includes the medium finding (3) in the fix list despite `--min high`
- Includes the nit (4) in the fix list
- Proposes merging before a re-review
- Plans to merge the PR even though the request contains no merge intent
- Assigns a numeric 1-10 score or a 9.0 style merge threshold
