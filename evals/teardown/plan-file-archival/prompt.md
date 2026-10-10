---
name: teardown-plan-file-archival
description: Archive completed plan files while preserving reference PRD files and active worktrees
tags: [teardown]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

Clean factory. I have PLAN-t01.md and PLAN-t02.md files from old worktrees, plus a PRD-main.md in the root. I also have 2 active worktrees (t07 and t08) still being worked on. After cleanup, the factory should only have the active ones left.
