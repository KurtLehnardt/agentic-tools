---
name: validate-install-crashed-run-orphan-cleanup
description: Cleans up orphans from a crashed validation run using only the run tag and verifies with a sweep
tags: [validate-install]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

my laptop died halfway through a validation run last night. ensure everything for validation is cleaned up. i also have a prod box and a bastion in that same account so be careful
