---
type: llm
weight: 1
---

PASS if:
- States that the pre-flight check passed (npm test and npm run build succeeding)
- Prompts for clarification on staging vs. production since "go live" is ambiguous
- States it confirmed the target with the user before proceeding
- States migrations were executed, if any were pending
- Names the platform it deployed via
- States health checks were run
- States the health check failed (HTTP 500 on /api/health), and that this triggered rollback
- Explicitly describes the rollback execution (names the vercel rollback command or git revert)
- States the previous deployment is now live again
- Reports that the code deployment was rolled back
- Notes that applied migrations may need manual review

FAIL if:
- Does not prompt for clarification on staging vs. production target
- States or implies the broken deployment was left live after health check failure
- Does not describe rollback steps being taken
- States or implies the rollback process was skipped
- Does not state the previous deployment is now active again
- Does not acknowledge migration review considerations in the report
