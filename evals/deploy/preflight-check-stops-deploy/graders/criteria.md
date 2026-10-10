---
type: llm
weight: 1
---

PASS if:
- Pre-flight check is the first action
- Runs git status, requiring clean working tree
- Checks current branch (must be on main or release branch)
- Fetches origin to verify up-to-date status
- Runs npm test (must pass with no failures)
- Runs npm run build (must succeed)
- Runs TypeScript check
- If any pre-flight check fails (e.g., npm test returns exit code 1), stops immediately
- Reports the specific failure encountered
- Clearly indicates which phase failed
- Does not proceed to target selection or any deployment steps

FAIL if:
- Skips or reduces pre-flight checks
- Proceeds to deployment despite failed npm test or build
- Does not check branch status or git status
- Skips git status check
- Does not stop at first failure
- Attempts to deploy broken code
- Does not clearly report which phase failed
