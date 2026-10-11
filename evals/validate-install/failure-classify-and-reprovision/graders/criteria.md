---
type: llm
weight: 1
---

PASS if:
- Classifies the failure as a README bug (missing prerequisite), not a code bug or environment problem
- Proposes a README fix that adds the Node.js and pnpm prerequisite or install step
- States the fix goes on a branch (for example `fix/validate-install-<run-id>`) and not on the default branch
- States that attempt 2 runs on a brand-new instance, not the one that failed
- States that every step re-runs from the start on the fresh instance
- States that the failed attempt's resources are torn down
- Names the limit of 3 attempts per target

FAIL if:
- Installs pnpm on the existing instance and continues from step 3
- Classifies the failure as an environment problem
- Reuses the failed instance for the next attempt
- Omits teardown of the failed attempt
