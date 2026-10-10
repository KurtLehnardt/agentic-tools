---
type: llm
weight: 1
---

PASS if:
- Identifies hardcoded database password in DB_CONFIG as CRITICAL security vulnerability
- Identifies hardcoded Stripe and SendGrid API keys as CRITICAL security vulnerabilities
- Identifies SQL injection in /search endpoint (LIKE query concatenation) as CRITICAL
- Identifies SQL injection in /find-by-email endpoint as CRITICAL
- Presents corrected code inline moving secrets to environment variables (e.g. `process.env.DB_PASSWORD`, `process.env.STRIPE_KEY`) for all CRITICAL hardcoded-secret issues
- Presents corrected code inline using parameterized queries for the SQL injection vulnerabilities
- Identifies exposing error stack traces as HIGH security issue
- Identifies missing input validation on payment amounts as HIGH issue
- Identifies hardcoded JWT secret as HIGH issue and presents corrected code moving it to an environment variable
- Reports missing rate limiting on login endpoint as MEDIUM issue (only reports, doesn't fix)
- Explains that all CRITICAL security issues must be fixed before deployment
- Provides clear before/after examples showing how SQL injection is prevented

FAIL if:
- Misses any of the CRITICAL SQL injection vulnerabilities
- Fails to identify hardcoded secrets as CRITICAL vulnerabilities
- Only reports security issues without presenting corrected code for the CRITICAL/HIGH ones
- Presents corrected code for MEDIUM/LOW issues when CRITICAL/HIGH should be the priority
- Suggests the codebase is mostly secure when it has multiple injection vectors
- Does not distinguish between SQL injection (use parameterized queries) and hardcoded secrets (use environment variables)
- Leaves hardcoded passwords or API keys in the corrected code it presents
- Does not provide specific remediation steps
