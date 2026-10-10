# agentic-tools

Claude Code plugin that implements a full autonomous code factory. Give it an idea — it produces a running application.

## The Pipeline

```
/determine-market-interest → /idea → /setup → /build → /test → /deploy → /ship
                                                                            /status (anytime)
                                                                            /teardown
```

| Skill | Purpose |
|-------|---------|
| `/determine-market-interest` | Is there a market? Discover opportunities (high demand, low supply) or validate one idea you already have |
| `/idea` | Raw idea → structured PRD with acceptance criteria and service manifest |
| `/setup` | Detect required services, check vaults, generate .env, guide account creation |
| `/build` | 7-phase implementation: plan → architect gate → product gate → workers → gate-check + judge → integration |
| `/test` | Generate test suites for existing code without modifying implementation |
| `/deploy` | Deploy to staging/production, run migrations, health check, rollback on failure |
| `/ship` | Go-to-market engine: strategy doc, landing page, free tool, SEO, AEO infrastructure |
| `/status` | Factory dashboard: active builds, scores, blockers, environment health |
| `/teardown` | Clean up worktrees, delete merged branches, archive plans |

## The Machinery

A second layer of skills for running the factory the way high-throughput agentic teams actually do: write **contracts** (not prompts), gate on checks a stub can't pass, let cheap owners build and expensive gatekeepers doubt, grow evals from real failures, and bound what a tricked agent can touch. Distilled from conference talks on 24/7 agent fleets, self-hosted models, harness design, agent security, and LLM ops.

```
ALIGN → EXECUTE ──────────────→ MEASURE ─────────────→ OBSERVE → GUARD
/contract  /route /survive /gate  /verdict /capture /chain-risk  /observe  /sandbox /constitution
```

| Skill | Stage | Purpose |
|-------|-------|---------|
| `/contract` | Align | Declarative objective + machine-checkable acceptance criteria; refuses prompt-as-wish and imperative pseudocode |
| `/gate` | Execute | Build an executable gate, then prove it's stub-proof — if a stub passes, the eval is the bug |
| `/route` | Execute | Route each task to the cheapest model/effort that passes its gate; escalate on failure; prefer local for narrow work |
| `/survive` | Execute | Wrap a worker loop (validate, rescue-parse, nudge, step-enforce, compact) so small/local models actually finish |
| `/verdict` | Measure | Zero-trust gatekeeper: refetch from source, rerun the suite firsthand, score claim-by-claim, never trust say-so |
| `/capture` | Measure | Turn a failure into a permanent, reproducible eval level so it can't silently return |
| `/chain-risk` | Measure | Compounding-error math (`p^n`) → where to place gates so pipeline reliability stays above target |
| `/observe` | Observe | Structured spans + four signals (P95 latency, $/run, err%, eval-pass); start with one critical use case |
| `/sandbox` | Guard | Deny-by-default policy + per-MCP-server containment + violation telemetry; bounds blast radius (doesn't stop injection) |
| `/constitution` | Guard | Pin a north-star and protect the prompt layer from tampering and injected redirection of downstream agents |

These compose with the pipeline: `/contract` feeds `/build`, `/gate` hardens what `/build`'s workers must pass, `/verdict` is the merge gate, and `/observe` + `/capture` close the loop back into better routing and evals.

## How It Works

### `/determine-market-interest` — Market Validation
Answers whether anyone actually wants the thing, in two modes.

**Discovery** — you don't know what to build. Fans subagents out across problem domains to generate transactional search queries, kills the doomed candidates before spending research budget on them, verifies what tools actually exist (with URLs — no claim without a link), then pays a skeptic subagent to destroy the survivors. Returns a ranked shortlist.

```
/determine-market-interest --deep
```

**Validation** — you have an idea and want a verdict. Derives the queries real users would type (not your framing of the solution), then runs the same gate, supply verification, scoring, and skeptic pass against that one idea. Returns **BUILD**, **NARROW**, **PIVOT**, or **DON'T BUILD**, with the condition that would reverse it.

```
/determine-market-interest "an app that tracks kids' chores and pays allowance automatically"
```

Scores `Demand × Supply gap × Monetizability × Build ease` and appends to a ledger, so repeat runs compound instead of re-deriving the same dead ends.

Works with or without a keyword API key. With one, volumes are labeled `Data`; without, `Estimated` — and the report's first line always says which. Set `DATAFORSEO_LOGIN` and `DATAFORSEO_PASSWORD` for measured volumes at about nine cents per run.

### `/idea` — Intake
Takes a raw concept and produces a Product Requirements Document with measurable acceptance criteria, technical requirements, and a service manifest listing every external dependency.

### `/setup` — Environment
Reads the PRD (or scans the codebase), detects what services are needed, checks your credential vault (1Password CLI, AWS SSM, or .env files), and generates a complete environment configuration. For missing services, it produces a checklist with direct signup links.

### `/build` — Implementation
The core engine. Runs a 7-phase, spec-driven pipeline with binary PASS/FAIL gates (no scores):

1. **Roadmap** — Explore codebase, produce implementation plan mapped to requirement IDs
2. **Architect Gate** — Binary technical conformance checklist; any FAIL blocks
3. **Product Gate** — Binary acceptance-criteria checklist; any FAIL blocks
4. **Task Decomposition** — Break plan into non-colliding worktree-safe tasks, each with a model tier
5. **Worker Swarm** — One-shot tiered workers on isolated git worktrees
6. **Gate + Judge** — Deterministic `gate-check.sh` first, then an opus judge; only APPROVED tasks merge, incrementally, into an assembly branch
7. **Verify & Deliver** — Final integration gate and integration judge on the assembly branch

**`--quickly`** — `/build --quickly` is a low-token variant. It keeps the orchestrator and subagent-worker pattern (isolated worktrees, deterministic `gate-check.sh`) but drops the architect and product gates and all per-task review. It ends with one opus review of the full PR and at most one fix round. The PR is never merged for you. Not for BINDING contracts, production migrations, or auth rewrites; use the full pipeline for those. See `skills/build/references/quick-mode.md`.

### `/test` — Coverage
Analyzes existing code for coverage gaps, prioritizes by risk (auth, payments, data mutations first), and generates comprehensive test suites following existing patterns. Does not modify implementation.

### `/deploy` — Ship
Pre-flight validation, database migrations, deployment to Vercel/hosting platform, post-deployment health checks, and automatic rollback if health checks fail. Production deploys require human confirmation.

### `/status` — Dashboard
Read-only snapshot of the factory: active worktrees, review scores, blockers, environment health, backlog status. No subagents dispatched — reads local state directly.

### `/ship` — Go-to-Market
Takes any app (codebase, URL, or description) and produces a tailored marketing strategy + working deliverables. Runs a 5-phase pipeline:

1. **Discover** — Explore the product, understand positioning and differentiators
2. **Expert Reviews** — Parallel UX architect + business executive subagent critiques
3. **Strategy** — Prioritized GTM document covering 8 distribution strategies with 90-day action plan
4. **Build Deliverables** — Landing page, free lead-gen tool, SEO guide pages, AEO infrastructure (parallel worktrees)
5. **Review & Deliver** — Critic review, fix critical issues, create PRs

Adapts to product maturity: early-stage gets positioning + strategy, growth-stage gets concrete deliverables and scaling tactics.

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
# Don't have an idea yet? Find one.
/determine-market-interest --deep

# Already have one? Get a verdict.
/determine-market-interest "my idea in a sentence"

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

# Go to market
/ship

# Check on things
/status

# Clean up after merge
/teardown
```

## Customization

### Review Gates
Gates are binary PASS/FAIL checklists. Edit the checklists in:
- `skills/build/references/architect-review-prompt.md`
- `skills/build/references/executive-review-prompt.md`

### Worker Behavior
Modify `skills/build/references/worker-prompt.md` for commit conventions, validation commands, scope rules.

### Test Patterns
Modify `skills/test/references/test-writer-prompt.md` for test framework preferences, coverage targets.

## Structure

```
agentic-tools/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── determine-market-interest/
│   │   ├── SKILL.md
│   │   ├── scripts/
│   │   │   └── keyword-volume.mjs
│   │   └── references/
│   │       ├── domain-agent-prompt.md
│   │       ├── demand-estimation.md
│   │       ├── supply-assessment.md
│   │       ├── kill-gate.md
│   │       └── data-providers.md
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
│   │       ├── worker-prompt.md
│   │       ├── quick-mode.md
│   │       └── critic-review-prompt.md
│   ├── test/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── test-writer-prompt.md
│   ├── deploy/
│   │   └── SKILL.md
│   ├── ship/
│   │   ├── SKILL.md
│   │   └── evals/
│   │       └── evals.json
│   ├── status/
│   │   └── SKILL.md
│   ├── teardown/
│   │   └── SKILL.md
│   │
│   │   # machinery layer (see "The Machinery" above)
│   ├── contract/       └── SKILL.md
│   ├── gate/           └── SKILL.md
│   ├── route/          └── SKILL.md
│   ├── survive/        └── SKILL.md
│   ├── verdict/        └── SKILL.md
│   ├── capture/        └── SKILL.md
│   ├── chain-risk/     └── SKILL.md
│   ├── observe/        └── SKILL.md
│   ├── sandbox/        └── SKILL.md
│   └── constitution/   └── SKILL.md
├── CLAUDE.md
├── README.md
└── LICENSE
```

## License

MIT
