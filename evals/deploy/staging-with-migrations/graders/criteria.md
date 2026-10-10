---
type: llm
weight: 1
---

PASS if:
- Runs pre-flight validation including clean git status, passing tests, and successful build
- Identifies staging as the target environment
- Executes database migrations before code deploy, specifically mentioning profiles table migration
- Deploys to Vercel staging environment
- Runs health checks confirming HTTP 200 on / and /api/health endpoints
- Captures and reports the staging deployment URL

FAIL if:
- Does not run complete pre-flight checks
- Deploys to production instead of staging
- Skips pre-flight validation
- Does not mention migrations or the profiles table
- Fails to verify health checks return 200
- Does not report the deployment URL
