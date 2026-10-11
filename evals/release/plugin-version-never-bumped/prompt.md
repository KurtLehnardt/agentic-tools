---
name: release-plugin-version-never-bumped
description: Plugin changed since last tag but plugin.json still 1.1.0
tags: [release]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

cut a release of our claude plugin. plugin.json says 1.1.0 and the last tag is v1.1.0, but there are 14 commits since then (8 feat, 3 fix) touching skills/. just publish it and update my local install
