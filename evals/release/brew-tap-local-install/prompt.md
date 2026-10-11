---
name: release-brew-tap-local-install
description: Homebrew tap release merges the PR by repo convention, updates the formula, then reinstalls and validates
tags: [release]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

tag a release for my cli, it ships through my homebrew tap kurt/tap. merge PR 42 first (gh pr checks 42 is all green), then publish the version and update my local install. current version 0.4.2, one fix commit since
