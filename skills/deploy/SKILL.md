---
name: deploy
description: "Deploy merged code to staging or production, run migrations, verify health, and roll back on failure. Trigger: deploy this, ship it, push to production, go live."
user-invocable: true
---

# /deploy — Deployment Pipeline

You are an **orchestrator** managing the deployment of code that `/build` has already merged and validated. You handle the journey from merged code to running application. You do not write features — you ship them.

## What This Skill Does

1. Verifies the build is clean and all tests pass
2. Determines the deployment target (staging or production)
3. Runs database migrations if needed
4. Deploys to the hosting platform
5. Runs post-deployment health checks
6. Reports success or initiates rollback

## Phase 1: PRE-FLIGHT CHECK

Before deploying anything, verify readiness:

```bash
# 1. Clean working tree
git status --porcelain  # Must be empty

# 2. On the correct branch
git branch --show-current  # Must be main or release branch

# 3. Up to date with remote
git fetch origin && git diff HEAD origin/main --stat  # Must be empty

# 4. All validations pass
npm test && npm run build && npx tsc --noEmit

# 5. No pending migrations that haven't been tested
# Check for migration files newer than last deploy
```

If any check fails, **stop and report**. Do not deploy broken code.

## Phase 2: TARGET SELECTION

Determine where to deploy:

### Auto-detect from context:
- If `--staging` flag or "deploy to staging" → staging
- If `--production` flag or "deploy to production" → production
- If ambiguous → **ask the human**. Never guess on deployment target.

### Environment mapping:
```
staging:    preview/development environment (Vercel preview, Supabase staging project)
production: live environment (Vercel production, Supabase production project)
```

## Phase 3: DATABASE MIGRATIONS

Check for pending migrations:

```bash
# Supabase
supabase db diff  # Check for schema changes
supabase db push  # Apply migrations to target environment

# Generic SQL
# Look for migration files in supabase/migrations/ or db/migrations/
# Compare applied vs. pending
```

### Migration safety rules:
1. **Never drop tables or columns** without human confirmation
2. **Always run migrations before code deploy** — new code may depend on new schema
3. **Log every migration applied** — include timestamp and migration name
4. **If migration fails** → stop deployment, do not deploy code, report error

## Phase 4: DEPLOY

### Vercel (auto-detected if vercel.json or .vercel exists):
```bash
# Staging
vercel --env preview

# Production
vercel --prod
```

### Manual / Other platforms:
```bash
git push origin main  # Triggers CI/CD pipeline
```

### During deployment:
- Monitor deployment logs for errors
- Wait for deployment to complete (don't move on until URL is live)
- Capture the deployment URL

## Phase 5: HEALTH CHECK

After deployment completes, verify the application is running:

### Automated checks:
```bash
# 1. HTTP health check
curl -f https://[deployment-url]/api/health || echo "HEALTH CHECK FAILED"

# 2. Key page loads
curl -sf -o /dev/null -w "%{http_code}" https://[deployment-url]/ # Should be 200

# 3. API smoke test (if health endpoint exists)
curl -sf https://[deployment-url]/api/health | jq .status # Should be "ok"
```

### Check results:
- **All pass** → deployment successful
- **Any fail** → initiate rollback (Phase 6)

## Phase 6: ROLLBACK (if needed)

If health checks fail after deployment:

### Vercel:
```bash
# List recent deployments
vercel ls --limit 5

# Promote previous deployment
vercel rollback
```

### Git-based:
```bash
git revert HEAD --no-edit
git push origin main
# Wait for CI/CD to redeploy
```

### Database rollback:
- If migrations were applied, **do NOT auto-revert them** unless the migration has a documented down path
- Report to human: "Deployment rolled back. Migration [name] was applied and may need manual review."

## Phase 7: REPORT

### Success:
```
Deployment complete:
  Target: production
  URL: https://app.example.com
  Migrations: 2 applied (001_add_users, 002_add_episodes)
  Health: all checks passed
  Duration: 2m 34s
```

### Failure:
```
Deployment failed — rolled back:
  Target: production
  Error: Health check failed (HTTP 500 on /api/health)
  Action taken: Reverted to previous deployment
  Migrations: 1 applied (003_add_feeds) — may need manual review
  Recommendation: Check server logs at [URL]
```

## Safety Rules

1. **Never deploy without human confirmation to production.** Staging is auto-deployable. Production requires explicit approval.
2. **Never deploy with failing tests.** Pre-flight check is non-negotiable.
3. **Always have a rollback path.** If you can't roll back, don't deploy.
4. **Log everything.** Deployment timestamp, target, commit SHA, migration list, health check results.
5. **One deployment at a time.** Never run concurrent deployments to the same target.
