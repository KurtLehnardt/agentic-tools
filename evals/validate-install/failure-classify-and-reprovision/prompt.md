---
name: validate-install-failure-classify-and-reprovision
description: Classifies an attempt-1 failure as a README bug, fixes on a branch, and re-runs on a fresh instance
tags: [validate-install]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

test on linux VM, here's what happened on attempt 1 (ubuntu 24.04, t3.large):

```
# step:     3
# command:
#   pnpm install
# ---- output ----
bash: line 1: pnpm: command not found
# ---- exit 127 after 0s ----
```

the README never mentions node or pnpm. what now
