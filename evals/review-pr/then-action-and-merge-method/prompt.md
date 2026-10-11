---
name: review-pr-then-action-and-merge-method
description: Parses --then, detects merge convention from repo settings, shows full plan
tags: [review-pr]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

critique the PR, fix any findings that aren't nitpick, and merge. then rebuild the android app. repo settings from gh repo view: squashMergeAllowed true, mergeCommitAllowed false, rebaseMergeAllowed false
