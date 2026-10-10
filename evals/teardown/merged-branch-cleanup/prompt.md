---
name: teardown-merged-branch-cleanup
description: Clean up three merged feature branches, worktrees, and plan files with full phase execution
tags: [teardown]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

I just merged three feature branches (build/t01-auth, build/t02-payments, build/t03-logging) into main. Can you clean up the merged worktrees and branches? They're in .claude/worktrees/t01, t02, t03. I want to recover disk space.
