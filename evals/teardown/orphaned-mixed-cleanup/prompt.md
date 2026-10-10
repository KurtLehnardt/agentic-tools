---
name: teardown-orphaned-mixed-cleanup
description: Handle mix of orphaned worktrees and merged branches with unmerged commit detection
tags: [teardown]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

I have orphaned worktrees from old builds. Some are broken (branch deleted but worktree still exists). Also have 5 merged branches that are ready to delete. Can you identify orphans, prune them, and clean up the merged stuff? Be careful with anything that has unmerged commits.
