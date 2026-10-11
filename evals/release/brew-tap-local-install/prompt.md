---
name: release-brew-tap-local-install
description: Homebrew tap release updates formula then reinstalls and validates
tags: [release]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

tag a release for my cli, it ships through my homebrew tap kurt/tap. merge PR 42 first (CI is green), then publish the version and update my local install. current version 0.4.2, one fix commit since
