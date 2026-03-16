# agentic-tools

Claude Code plugin that implements a full autonomous code factory. Give it an idea — it produces a running application.

## The Pipeline

```
/idea → /setup → /build → /test → /deploy → /teardown
                                               /status (anytime)
```

| Skill | Purpose |
|-------|---------|
| `/idea` | Raw idea → structured PRD with acceptance criteria and service manifest |
| `/setup` | Detect required services, check vaults, generate .env, guide account creation |
| `/build` | 7-phase implementation: plan → architect review → exec review → workers → critic → merge |
| `/test` | Generate test suites for existing code without modifying implementation |
| `/deploy` | Deploy to staging/production, run migrations, health check, rollback on failure |
| `/status` | Factory dashboard: active builds, scores, blockers, environment health |
| `/teardown` | Clean up worktrees, delete merged branches, archive plans |

## How It Works

### `/idea` — Intake
Takes a raw concept and produces a Product Requirements Document with measurable acceptance criteria, technical requirements, and a service manifest listing every external dependency.

### `/setup` — Environment
Reads the PRD (or scans the codebase), detects what services are needed, checks your credential vault (1Password CLI, AWS SSM, or .env files), and generates a complete environment configuration. For missing services, it produces a checklist with direct signup links.

### `/build` — Implementation
The core engine. Runs a 7-phase pipeline with scored quality gates:

1. **Roadmap** — Explore codebase, produce implementation plan
2. **Architect Review** — Technical review, >= 9.5/10 to proceed
3. **Executive Review** — Product/UX review, >= 9.5/10 to proceed
4. **Task Decomposition** — Break plan into non-colliding worktree-safe tasks
5. **Ralph Swarm** — Parallel worker agents on isolated git worktrees
6. **Critic Review** — Code review per worker, >= 9.5/10 to commit
7. **Merge & Cleanup** — Merge approved branches, clean worktrees

### `/test` — Coverage
Analyzes existing code for coverage gaps, prioritizes by risk (auth, payments, data mutations first), and generates comprehensive test suites following existing patterns. Does not modify implementation.

### `/deploy` — Ship
Pre-flight validation, database migrations, deployment to Vercel/hosting platform, post-deployment health checks, and automatic rollback if health checks fail. Production deploys require human confirmation.

### `/status` — Dashboard
Read-only snapshot of the factory: active worktrees, review scores, blockers, environment health, backlog status. No subagents dispatched — reads local state directly.

### `/teardown` — Cleanup
Removes merged worktrees and branches, archives completed plan files, prunes orphaned references. Never deletes unmerged work without human confirmation.

## Installation

Add to your `~/.claude/settings.json`:

```json
{
  "enabledPlugins": {
    "agentic-tools@C:\\path\\to\\agentic-tools": true
  }
}
```

Or clone and reference:

```bash
git clone https://github.com/KurtLehnardt/agentic-tools.git
```

## Quick Start

```
# Start with an idea
/idea I want a SaaS that converts podcast episodes into blog posts

# Set up the environment
/setup

# Build it
/build

# Add test coverage
/test

# Ship it
/deploy

# Check on things
/status

# Clean up after merge
/teardown
```

## Customization

### Review Thresholds
Default pass threshold is 9.5/10. Edit scoring rules in:
- `skills/build/references/architect-review-prompt.md`
- `skills/build/references/executive-review-prompt.md`
- `skills/build/references/critic-review-prompt.md`

### Worker Behavior
Modify `skills/build/references/ralph-worker-prompt.md` for commit conventions, validation commands, scope rules.

### Test Patterns
Modify `skills/test/references/test-writer-prompt.md` for test framework preferences, coverage targets.

## Structure

```
agentic-tools/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── idea/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── prd-review-prompt.md
│   ├── setup/
│   │   └── SKILL.md
│   ├── build/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── architect-review-prompt.md
│   │       ├── executive-review-prompt.md
│   │       ├── ralph-worker-prompt.md
│   │       └── critic-review-prompt.md
│   ├── test/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── test-writer-prompt.md
│   ├── deploy/
│   │   └── SKILL.md
│   ├── status/
│   │   └── SKILL.md
│   └── teardown/
│       └── SKILL.md
├── CLAUDE.md
├── README.md
└── LICENSE
```

## License

MIT
