---
name: release-dry-run-red-ci
description: dry-run prints commands; red CI stops the release
tags: [release]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

/release minor --dry-run. heads up CI is red on main right now, the last run failed
