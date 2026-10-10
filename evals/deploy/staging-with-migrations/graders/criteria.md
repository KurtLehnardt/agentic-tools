---
type: llm
weight: 1
---

PASS if:
- States that pre-flight validation was performed, including clean git status, passing tests, and a successful build
- Identifies staging as the target environment
- States that database migrations were executed before code deploy, specifically naming the profiles table migration
- States it deployed to the Vercel staging environment
- States health checks were run and confirms HTTP 200 on / and /api/health endpoints
- Captures and reports the staging deployment URL

FAIL if:
- Does not mention pre-flight checks being run
- States or implies it deployed to production instead of staging
- States or implies pre-flight validation was skipped
- Does not mention migrations or the profiles table
- Does not state that health checks returned 200
- Does not report the deployment URL
