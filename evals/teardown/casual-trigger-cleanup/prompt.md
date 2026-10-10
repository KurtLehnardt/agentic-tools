---
name: teardown-casual-trigger-cleanup
description: Recognize casual /teardown trigger with lowercase input and execute full cleanup phases
tags: [teardown]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

/teardown — i have some old build dirs taking up space. can you run the factory cleanup and remove anything that's been merged? just clean up for me.
