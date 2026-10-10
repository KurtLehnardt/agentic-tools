---
name: survive-premature-completion
description: Block premature 'done' claims via step/workflow enforcement
tags: [survive]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

/survive — I'm running a Mistral 7B worker agent for a multi-step task (steps 1-5 with acceptance criteria). At step 3 the model works, step 4 works, then the model claims 'done' before step 5 runs. How do I block it from declaring completion before all criteria are met?
