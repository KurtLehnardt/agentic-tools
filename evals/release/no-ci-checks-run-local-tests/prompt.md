---
name: release-no-ci-checks-run-local-tests
description: No checks on HEAD means warn and run local tests, not block forever
tags: [release]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

release a patch. this repo has no CI. the check-runs and statuses for HEAD are both empty. package.json has an npm test script. one fix commit since v1.2.3
