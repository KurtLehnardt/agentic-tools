---
name: release-version-sources-disagree
description: package.json and Cargo.toml disagree before bump
tags: [release]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

release a patch. package.json says 2.3.1, Cargo.toml says 2.3.0, VERSION says 2.3.1. last tag is v2.3.1. go ahead and tag it
