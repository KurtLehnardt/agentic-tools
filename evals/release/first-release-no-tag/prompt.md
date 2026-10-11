---
name: release-first-release-no-tag
description: No prior tag means the manifest version is used as is
tags: [release]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

cut the first release of this repo. there are no tags yet, package.json says 0.3.0, about 25 commits so far. no bump type given
