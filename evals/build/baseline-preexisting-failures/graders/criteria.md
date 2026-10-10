---
type: llm
weight: 1
---

PASS if:
- Phase 4.5 captures baseline by running gate-check.sh on origin/main
- baseline.json is created with the 2 pre-existing failing tests marked as 'known_failing_at_baseline'
- gate-check.sh runs in worker tasks reporting delta against baseline
- NEW test failures detected by gate-check.sh are reported as regressions
- The 2 pre-existing failures are NOT reported as task regressions
- gate-check.sh reports known pre-existing failures with 'known_failing_at_baseline' status
- Workers successfully complete despite pre-existing failures
- Judge verdicts reference the baseline context when evaluating task completeness
- Final verdict distinguishes between pre-build baseline failures and newly introduced failures
- Merge proceeds without failures introduced by the new code

FAIL if:
- baseline.json is not created or captured from origin/main
- Pre-existing failures are reported as task regressions
- Workers are marked as failed due to known pre-baseline failures
- gate-check.sh does not report delta against baseline
- Judge verdict does not reference baseline state when evaluating requirements
- Pre-baseline failing tests are not marked with 'known_failing_at_baseline' status
- Final report does not distinguish between pre-existing and newly introduced failures
- Baseline capture is skipped or not run on origin/main
