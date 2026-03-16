# agentic-tools

Claude Code plugin that implements a full orchestrator pipeline for autonomous software development.

## What It Does

The `/build` skill runs a 7-phase pipeline:

1. **Roadmap** — Explores codebase, produces implementation plan
2. **Architect Review** — Technical review, >= 9.5/10 to proceed
3. **Executive Review** — Product/UX review, >= 9.5/10 to proceed
4. **Task Decomposition** — Breaks plan into non-colliding worktree-safe tasks
5. **Ralph Swarm** — Parallel worker agents on isolated git worktrees
6. **Critic Review** — Code review per worker, >= 9.5/10 to commit
7. **Merge & Cleanup** — Merges approved branches, cleans worktrees

## Installation

### Option 1: Add to project settings

Add to your project's `.claude/settings.json`:

```json
{
  "plugins": [
    "C:\\path\\to\\agentic-tools"
  ]
}
```

### Option 2: Add to user settings

Add to `~/.claude/settings.json`:

```json
{
  "plugins": [
    "C:\\path\\to\\agentic-tools"
  ]
}
```

### Option 3: Clone and reference

```bash
git clone https://github.com/KurtLehnardt/agentic-tools.git
# Then add the path to your settings as above
```

## Usage

In any Claude Code session:

```
/build implement user authentication with OAuth
/build add a payment processing system
/build refactor the database layer
```

The orchestrator will:
- Plan the implementation
- Get it reviewed by architect and executive subagents
- Decompose into parallel tasks
- Dispatch worker agents on isolated worktrees
- Review each worker's output
- Merge everything when approved

## Customization

### Review Thresholds

The default pass threshold is 9.5/10. To adjust, edit the scoring rules in:
- `skills/build/references/architect-review-prompt.md`
- `skills/build/references/executive-review-prompt.md`
- `skills/build/references/critic-review-prompt.md`

### Worker Behavior

Modify `skills/build/references/ralph-worker-prompt.md` to change:
- Commit conventions
- Validation commands
- Scope rules
- Quality standards

### Iteration Limits

Defined in `skills/build/SKILL.md` Phase 4. Adjust per complexity tier.

## Structure

```
agentic-tools/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest
├── skills/
│   └── build/
│       ├── SKILL.md          # Main skill definition
│       └── references/
│           ├── architect-review-prompt.md
│           ├── executive-review-prompt.md
│           ├── ralph-worker-prompt.md
│           └── critic-review-prompt.md
├── CLAUDE.md                 # Plugin-level instructions
├── README.md
└── LICENSE
```

## License

MIT
