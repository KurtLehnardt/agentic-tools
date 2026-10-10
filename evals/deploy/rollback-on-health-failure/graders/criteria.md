---
type: llm
weight: 1
---

PASS if:
- Pre-flight check passes (npm test and npm run build succeed)
- Prompts for clarification on staging vs. production since "go live" is ambiguous
- Confirms target with user before proceeding
- Executes migrations if any are pending
- Deploys via appropriate platform
- Runs health checks
- Health checks fail (HTTP 500 on /api/health), triggering rollback
- Explicitly describes rollback execution (vercel rollback command or git revert)
- Confirms previous deployment is now live again
- Reports code deployment was rolled back
- Notes that applied migrations may need manual review

FAIL if:
- Does not prompt for clarification on staging vs. production target
- Leaves broken deployment live after health check failure
- Does not execute rollback steps
- Skips rollback process
- Does not confirm previous deployment is now active
- Does not acknowledge migration review considerations in the report
