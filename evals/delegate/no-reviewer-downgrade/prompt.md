---
name: delegate-no-reviewer-downgrade
description: Refuses to downgrade the reviewer model and escalates a failed worker one tier
tags: [delegate]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

delegate this: haiku workers already wrote 3 PRs for the small config fixes. to save tokens just have haiku review them too. also one worker keeps failing the same test, what do you do with it
