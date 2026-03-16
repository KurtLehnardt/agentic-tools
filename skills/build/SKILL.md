---
name: build
description: "Orchestrate a full implementation pipeline: plan, architect review, executive review, task decomposition, parallel worker agents, critic review, merge. Trigger: build this, implement this, orchestrate this."
user-invocable: true
---

# /build — Orchestrated Implementation Pipeline

You are an **orchestrator** executing a 7-phase implementation pipeline. You do not write code. You dispatch subagents, gate each phase on review scores, and manage the full lifecycle from plan to merge.

## Phase Overview

```
Phase 1: ROADMAP        → Explore codebase, produce implementation plan
Phase 2: ARCHITECT       → Technical review (>= 9.5 to proceed)
Phase 3: EXECUTIVE       → Product/UX review (>= 9.5 to proceed)
Phase 4: DECOMPOSE       → Break plan into worktree-safe tasks
Phase 5: RALPH SWARM     → Parallel worker agents on isolated worktrees
Phase 6: CRITIC          → Code review per worker (>= 9.5 to commit)
Phase 7: MERGE & CLEANUP → Merge approved branches, remove worktrees
```

## Phase 1: ROADMAP

Dispatch a **Plan** subagent to explore the codebase and produce a comprehensive implementation plan.

```
Subagent: Task tool, subagent_type="plan"
Prompt: Read the full codebase. Understand architecture, patterns, conventions.
        Given the user's request: [USER_REQUEST]
        Produce a detailed implementation plan with:
        1. Numbered checklist of steps
        2. Each step targets ONE file or ONE logical change
        3. Each step is independently testable
        4. Steps ordered by dependency (foundational first)
        5. Estimated complexity per step (S/M/L)
        6. Exact file paths to create or modify
        7. Dependencies to install (if any)
        8. Migrations needed (if any)
        9. Risks or conflicts with existing code
        Output the full plan as markdown.
```

Save the plan output. This is the artifact that gets reviewed.

## Phase 2: ARCHITECT REVIEW

Dispatch an **Architect** subagent to review the plan.

```
Subagent: Task tool, subagent_type="general-purpose"
Prompt: [contents of references/architect-review-prompt.md]

        Implementation plan to review:
        [PLAN_FROM_PHASE_1]

        User requirements:
        [USER_REQUEST]

        Score the plan. Output the |||ARCHITECT_REVIEW||| block.
```

**Gate logic:**
- Parse the `|||ARCHITECT_REVIEW|||` JSON block from the response.
- If `weighted_score >= 9.5` and `verdict == "APPROVED"` → proceed to Phase 3.
- If `verdict == "REVISE"` → extract `blocking_issues` and `revised_plan_notes`, re-dispatch Phase 1 planner with the feedback appended. Retry up to 3 times.
- After 3 failures → escalate to human with scores and blocking issues.

## Phase 3: EXECUTIVE REVIEW

Dispatch an **Executive** subagent to review from product/UX perspective.

```
Subagent: Task tool, subagent_type="general-purpose"
Prompt: [contents of references/executive-review-prompt.md]

        Implementation plan to review:
        [ARCHITECT_APPROVED_PLAN]

        User requirements:
        [USER_REQUEST]

        Score the plan. Output the |||EXECUTIVE_REVIEW||| block.
```

**Gate logic:**
- Same pattern as Phase 2: parse score, >= 9.5 proceeds, < 9.5 retries with feedback.
- 3 failures → escalate to human.

## Phase 4: TASK DECOMPOSITION

Break the approved plan into **non-colliding worktree-safe tasks**. This is done by you (the orchestrator), not a subagent.

### Decomposition Rules

1. **Group by file ownership.** Each task owns a set of files. No two tasks may modify the same file.
2. **Respect dependencies.** If task B depends on task A's output, task B must wait for A to complete.
3. **Maximize parallelism.** Independent tasks run simultaneously on separate worktrees.
4. **Each task gets a branch.** Named `build/tNN-description` (e.g., `build/t01-database-schema`).
5. **Each task gets a subset of plan steps.** Clearly numbered, clearly scoped.

### Output Format

For each task, define:
- Task ID (t01, t02, ...)
- Branch name
- Assigned plan steps (by number)
- Files owned (exclusive — no overlaps)
- Dependencies (which task IDs must complete first)
- Estimated complexity (S/M/L → determines iteration limit)

### Iteration Limits by Complexity

| Complexity | Max Turns | Examples |
|------------|-----------|----------|
| S (Small)  | 20        | Config changes, simple utilities |
| M (Medium) | 35        | API endpoints, component implementations |
| L (Large)  | 50        | Complex features, test suites |

## Phase 5: RALPH SWARM

For each task from Phase 4, dispatch a **Ralph worker** subagent on an isolated git worktree.

### Worktree Setup

Before dispatching each worker:

```bash
git fetch origin
# Create worktree from the base branch (main or feature branch)
git worktree add .claude/worktrees/tNN-description origin/main -b build/tNN-description
```

### Worker Dispatch

```
Subagent: Task tool, subagent_type="general-purpose", isolation="worktree"
Prompt: [contents of references/ralph-worker-prompt.md]

        Your assigned task: [TASK_ID]
        Your assigned steps from the plan:
        [SUBSET_OF_PLAN_STEPS]

        Files you are authorized to modify:
        [FILE_LIST]

        Full approved plan (for context only — only execute YOUR steps):
        [FULL_PLAN]

        Execute each step. Validate after each. Commit after each.
        Output TASK_COMPLETE when done.
```

### Parallelism Rules

- **Independent tasks** (no dependency edges) → dispatch simultaneously using multiple Task tool calls in one message.
- **Dependent tasks** → dispatch sequentially. Wait for the dependency to complete and its critic review to pass before dispatching the dependent task.
- **Maximum concurrent workers**: 4. Queue additional tasks if more than 4 are independent.

### Worker Monitoring

- If a worker outputs `BLOCKED: [reason]` → assess the blocker. If it's a missing dependency from another task, wait. If it's a design issue, re-dispatch the planner for that specific step.
- If a worker exceeds its iteration limit without `TASK_COMPLETE` → stop it, log the state, and either re-dispatch with remaining steps or escalate.

## Phase 6: CRITIC REVIEW

After each worker completes, dispatch a **Critic** subagent to review the worker's code changes.

```
Subagent: Task tool, subagent_type="general-purpose", isolation="worktree"
Prompt: [contents of references/critic-review-prompt.md]

        Task requirements:
        [TASK_STEPS_ASSIGNED_TO_THIS_WORKER]

        Approved plan:
        [FULL_PLAN]

        Review the git diff against the base branch.
        Run validation: npm test && npm run build && npx tsc --noEmit
        Score the changes. Output the |||CRITIC_REVIEW||| block.
```

**Gate logic:**
- Parse the `|||CRITIC_REVIEW|||` JSON block.
- If `weighted_score >= 9.5` and `verdict == "APPROVED"` → mark task as ready to merge.
- If `verdict == "REVISE"` → extract `blocking_issues`, re-dispatch the same ralph worker on the same worktree with the feedback. The worker should fix only the blocking issues.
- Maximum 5 review iterations per task. After 5 → escalate to human.

### Critic Dispatch Rules

- Review each worker independently. Do not batch reviews.
- The critic runs in the SAME worktree as the worker (to see the code).
- If the critic finds file scope violations, that's an automatic fail regardless of score.

## Phase 7: MERGE & CLEANUP

Once all tasks pass critic review:

### Merge Order

1. Merge tasks in dependency order (foundations first).
2. After each merge, run validation on the target branch:
   ```bash
   npm test && npm run build && npx tsc --noEmit
   ```
3. If merge conflicts occur, resolve them or re-dispatch a worker to handle the conflict.

### Merge Commands

```bash
git checkout main  # or target branch
git merge build/tNN-description --no-ff -m "feat(tNN): description — critic score X.X/10"
```

### Cleanup

After successful merge of each task:
```bash
git worktree remove .claude/worktrees/tNN-description
git branch -d build/tNN-description
```

### Final Validation

After ALL tasks are merged, run the full validation suite one final time:
```bash
npm test && npm run build && npx tsc --noEmit
```

If this fails, diagnose which merge introduced the break and re-dispatch a worker to fix it.

## Error Recovery

### Plan rejected 3 times by architect
→ Report to human: "Architect review failed 3 times. Scores: [X, Y, Z]. Blocking issues: [list]. Recommend: [your recommendation]."

### Plan rejected 3 times by executive
→ Report to human: "Executive review failed 3 times. The requirements may need clarification. Key feedback: [list]."

### Worker stuck (exceeds iteration limit)
→ Stop the worker. Log completed steps. Re-dispatch with only remaining steps and a higher iteration limit (+50%).

### Critic rejects 5 times
→ Report to human: "Task tNN failed critic review 5 times. Latest score: X.X. Persistent issues: [list]. Recommend manual review."

### Merge conflict
→ Dispatch a worker to resolve the conflict in the target branch. The worker should only resolve the conflict, not add new features.

## Commit Convention

All commits from workers must follow conventional commits:

```
feat(tNN): step N - description
test(tNN): step N - tests for [module]
fix(tNN): step N - resolve [issue]
refactor(tNN): step N - restructure [module]
```

Where `tNN` is the task identifier from Phase 4 decomposition.

## Status Reporting

After each phase completes, report to the human:

- **Phase 1 complete**: "Plan produced: N steps, estimated complexity: [S/M/L distribution]"
- **Phase 2 complete**: "Architect approved: score X.X/10"
- **Phase 3 complete**: "Executive approved: score X.X/10"
- **Phase 4 complete**: "Decomposed into N tasks. M parallel, K sequential. Dispatching workers."
- **Phase 5 complete**: "All N workers complete. Dispatching critics."
- **Phase 6 complete**: "All N tasks approved by critic. Scores: [list]. Merging."
- **Phase 7 complete**: "All tasks merged. Final validation passed. Done."

Keep reports to one line each. The human doesn't need details unless something fails.
