---
name: build
description: "Orchestrate a full implementation pipeline: plan, architect review, executive review, task decomposition, parallel ralph-loop workers, critic review, merge. Trigger: build this, implement this, orchestrate this."
user-invocable: true
---

# /build — Orchestrated Implementation Pipeline

You are an **orchestrator** executing a 7-phase implementation pipeline. You do not write code. You dispatch subagents and ralph-loops, gate each phase on review scores, and manage the full lifecycle from plan to merge.

## Phase Overview

```
Phase 1: ROADMAP        → Explore codebase, produce implementation plan
Phase 2: ARCHITECT       → Technical review (>= 9.5 to proceed)
Phase 3: EXECUTIVE       → Product/UX review (>= 9.5 to proceed)
Phase 4: DECOMPOSE       → Break plan into worktree-safe tasks
Phase 5: RALPH SWARM     → Dispatch ralph-loop workers (iterative, self-correcting)
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

| Complexity | Max Iterations | Examples |
|------------|---------------|----------|
| S (Small)  | 10            | Config changes, simple utilities |
| M (Medium) | 20            | API endpoints, component implementations |
| L (Large)  | 35            | Complex features, test suites |

## Phase 5: RALPH SWARM

For each task from Phase 4, dispatch a **ralph-loop** worker. The ralph-loop plugin creates a self-correcting iterative loop — the worker keeps running until it outputs the completion promise or hits the max iteration limit.

### Worktree Setup

Before dispatching each worker:

```bash
git fetch origin
git worktree add .claude/worktrees/tNN-description origin/main -b build/tNN-description
```

### Worker Dispatch via Ralph Loop

For each task, write a prompt file and dispatch via `/ralph-loop`. The prompt includes the worker instructions, assigned steps, file list, and the full plan for context.

**Build the ralph-loop prompt** by combining:
1. The contents of `references/ralph-worker-prompt.md` (worker persona + rules)
2. The task-specific context (assigned steps, files, plan)
3. Inline critic instructions — the worker must self-review before declaring complete

```
/ralph-loop "
[contents of references/ralph-worker-prompt.md]

## Your Assignment

Task: [TASK_ID]
Branch: build/tNN-description
Working directory: .claude/worktrees/tNN-description

### Assigned steps:
[SUBSET_OF_PLAN_STEPS]

### Files you own (exclusive):
[FILE_LIST]

### Full plan (context only — execute YOUR steps only):
[FULL_PLAN]

## Self-Review Before Completion

Before outputting the completion promise, you MUST:
1. Run: npm run build && npx tsc --noEmit
2. Review your own git diff against the base branch
3. Check that ALL assigned steps are implemented
4. Verify no files outside your scope were modified
5. Ensure all commits follow conventional commit format

Only output <promise>TASK_COMPLETE</promise> when ALL of the above pass.
If stuck after 3 attempts on a step, output BLOCKED: [reason] in your response (but do NOT output the completion promise).
" --max-iterations [COMPLEXITY_LIMIT] --completion-promise "TASK_COMPLETE"
```

### Parallelism Rules

- **Independent tasks** (no dependency edges) → dispatch simultaneously. Each gets its own ralph-loop in a separate terminal/session if possible. If running in a single session, dispatch sequentially.
- **Dependent tasks** → dispatch sequentially. Wait for the dependency's ralph-loop to complete (outputs `TASK_COMPLETE`) before starting the dependent task.
- **Maximum concurrent workers**: Limited by available sessions. In a single session, ralph-loops run sequentially.

### Worker Monitoring

- The ralph-loop plugin handles iteration automatically via the Stop hook.
- Each iteration, the worker sees its previous work in files and git history.
- If the worker outputs `BLOCKED: [reason]`, the loop continues but the worker should document the blocker.
- If max iterations reached without `TASK_COMPLETE`, the loop stops. Assess the state and either:
  - Re-dispatch with remaining steps and higher iteration limit (+50%)
  - Escalate to human

### Fallback: Subagent Workers

If the ralph-loop plugin is not installed or not available:

1. **Notify the user in the console:**

   > **ralph-loop plugin not detected.** Install it for iterative, self-correcting workers:
   >
   >     /plugin install ralph-skills@ralph-marketplace
   >
   > Continuing with one-shot subagent workers. The build will still complete, but workers won't auto-retry on failures or self-validate in a loop.

2. Fall back to one-shot subagent workers:

```
Subagent: Task tool, subagent_type="general-purpose"
Prompt: [same prompt as above, but without ralph-loop wrapper]
        Output TASK_COMPLETE when done.
```

## Phase 6: CRITIC REVIEW

After each worker's ralph-loop completes (outputs `TASK_COMPLETE`), dispatch a **Critic** subagent to review the worker's code changes. The critic runs as a separate subagent (NOT a ralph-loop) since it's a one-shot review.

```
Subagent: Task tool, subagent_type="general-purpose"
Prompt: [contents of references/critic-review-prompt.md]

        Task requirements:
        [TASK_STEPS_ASSIGNED_TO_THIS_WORKER]

        Approved plan:
        [FULL_PLAN]

        Working directory: .claude/worktrees/tNN-description

        Review the git diff against the base branch.
        Run validation: npm test && npm run build && npx tsc --noEmit
        Score the changes. Output the |||CRITIC_REVIEW||| block.
```

**Gate logic:**
- Parse the `|||CRITIC_REVIEW|||` JSON block.
- If `weighted_score >= 9.5` and `verdict == "APPROVED"` → mark task as ready to merge.
- If `verdict == "REVISE"` → extract `blocking_issues`, re-dispatch a new ralph-loop on the SAME worktree with the feedback appended to the prompt:

```
/ralph-loop "
[original worker prompt]

## CRITIC FEEDBACK — FIX THESE ISSUES:
[blocking_issues from critic]

Fix ONLY the blocking issues listed above. Do not re-implement completed steps.
Run validation after fixes. Output <promise>FIXES_COMPLETE</promise> when done.
" --max-iterations 10 --completion-promise "FIXES_COMPLETE"
```

- When the `FIXES_COMPLETE` ralph-loop finishes, re-run the same critic review. This counts as one review cycle.
- Maximum 5 critic review cycles per task (initial + fix rounds). After 5 → escalate to human.

### Critic Dispatch Rules

- Review each worker independently. Do not batch reviews.
- The critic reads code from the worker's worktree.
- If the critic finds file scope violations, that's an automatic fail regardless of score.

## Phase 7: MERGE & CLEANUP

Once all tasks pass critic review:

### Merge Order

1. Merge tasks in dependency order (foundations first).
2. After each merge, run validation on the target branch:
   ```bash
   npm test && npm run build && npx tsc --noEmit
   ```
3. If merge conflicts occur, resolve them or re-dispatch a ralph-loop to handle the conflict.

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

If this fails, diagnose which merge introduced the break and re-dispatch a ralph-loop to fix it.

## Error Recovery

### Plan rejected 3 times by architect
→ Report to human: "Architect review failed 3 times. Scores: [X, Y, Z]. Blocking issues: [list]. Recommend: [your recommendation]."

### Plan rejected 3 times by executive
→ Report to human: "Executive review failed 3 times. The requirements may need clarification. Key feedback: [list]."

### Worker stuck (ralph-loop hits max iterations)
→ Log completed steps from the worktree's git history. Re-dispatch with only remaining steps and a higher iteration limit (+50%).

### Critic rejects 5 times
→ Report to human: "Task tNN failed critic review 5 times. Latest score: X.X. Persistent issues: [list]. Recommend manual review."

### Merge conflict
→ Dispatch a ralph-loop to resolve the conflict in the target branch. The worker should only resolve the conflict, not add new features.

### Ralph-loop plugin not available
→ Print to console: "**ralph-loop plugin not detected.** Install it with: `/plugin install ralph-skills@ralph-marketplace` — the build will still work using one-shot subagents, but without iterative self-correction." Then fall back to one-shot subagent workers (Phase 5 fallback).

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
- **Phase 4 complete**: "Decomposed into N tasks. M parallel, K sequential. Dispatching ralph-loops."
- **Phase 5 complete**: "All N ralph-loops complete. Dispatching critics."
- **Phase 6 complete**: "All N tasks approved by critic. Scores: [list]. Merging."
- **Phase 7 complete**: "All tasks merged. Final validation passed. Done."

Keep reports to one line each. The human doesn't need details unless something fails.
