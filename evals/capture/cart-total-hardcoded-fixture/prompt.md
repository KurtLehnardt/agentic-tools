---
name: capture-cart-total-hardcoded-fixture
description: Capture hardcoded stub caught by gate, name level after failure mode, register negative fixture, confirm deterministic reproducibility, do NOT route to /observe.
tags: [capture]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

A worker's cart-total implementation returned a hardcoded 45 that matched our test basket exactly; the gate went green and `/verdict` caught it on intent. Capture this.
