---
name: status-casual-factory-status
description: Full dashboard despite casual input phrasing
tags: [status]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

show factory status


## Pre-gathered Repository State

The following data has already been collected from the repository (tool output pasted below as given input — treat it as the current disk/git state):

### git branch -a
```
* main
  build/t02-api-endpoints
  build/t03-frontend
  remotes/origin/main
```

### git worktree list
```
/Users/dev/agentic-tools-factory                                      a1b2c3d [main]
/Users/dev/agentic-tools-factory/.claude/worktrees/t02-api-endpoints   e4f5a6b [build/t02-api-endpoints]
/Users/dev/agentic-tools-factory/.claude/worktrees/t03-frontend        9c8d7e6 [build/t03-frontend]
```

### git log --oneline -20 (main)
```
a1b2c3d (HEAD -> main) merge: t01-database-schema into main (#1)
7f6e5d4 feat(t01): add database schema migrations
3b2a190 chore: bootstrap roadmap-progress.json
```

### git stash list
```
(empty)
```

### git status --porcelain
```
(empty — working tree clean)
```

### roadmap-progress.json
```json
{
  "tasks": [
    {"id": "t00-auth", "status": "completed", "scores": {"architect": 9.7, "executive": 9.5, "critic": 9.8}, "merged": true},
    {"id": "t01-database-schema", "status": "completed", "scores": {"architect": 9.6, "executive": 9.5, "critic": 9.7}, "merged": true},
    {"id": "t02-api-endpoints", "status": "in_progress", "dependencies": ["t01-database-schema"], "scores": {"architect": 9.4, "executive": null, "critic": null}, "steps_complete": 3, "steps_total": 10},
    {"id": "t03-frontend", "status": "blocked", "dependencies": ["t02-api-endpoints"], "block_reason": "waiting on t02-api-endpoints to merge"},
    {"id": "t05-payments", "status": "blocked", "scores": {"architect": 9.1, "executive": 8.9, "critic": 7.2}, "block_reason": "critic rejected: input validation missing on payment amount field"}
  ]
}
```

### Worktree contents

`.claude/worktrees/t02-api-endpoints`:
- Branch: `build/t02-api-endpoints`
- 1 commit (`e4f5a6b` "feat(t02): scaffold search endpoint", 5m ago)
- 2 files with uncommitted changes
- `PLAN-t02-api-endpoints.md` exists: 3/10 steps checked off

`.claude/worktrees/t03-frontend`:
- Branch: `build/t03-frontend`
- 0 commits
- No `PLAN-*.md` yet (task has not started — blocked on t02-api-endpoints)

### Environment health (pre-run, pasted as given)
```
npm test: 47 passed, 0 failed
npx tsc --noEmit: 0 errors
npm run build: success
Supabase: connected (env var present)
Anthropic: connected
Stripe: not configured (optional)
```
