---
name: review-pr-min-high-skips-medium
description: Threshold argument filters findings before the fix step; no merge intent means stop at ready to merge
tags: [review-pr]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

review-pr 88 --min high. the critic came back with these findings on PR 88: (1) critical src/auth.ts:41 token compare uses == so empty token matches empty hash, (2) high src/db.ts:120 missing await so write errors are swallowed, (3) medium src/ui.ts:9 spinner never hides on error, (4) nit src/ui.ts:30 rename variable. what do you do next?
