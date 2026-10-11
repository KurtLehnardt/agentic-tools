---
name: release-dry-run-red-ci
description: dry-run uses fetch not pull; a failed check on the HEAD commit stops the release
tags: [release]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

/release minor --dry-run. for the HEAD commit, the check run `lint` completed with conclusion failure and `unit` completed with success
