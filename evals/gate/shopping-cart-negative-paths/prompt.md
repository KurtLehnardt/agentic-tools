---
name: gate-shopping-cart-negative-paths
description: "Test gate includes positive and negative assertions with exact numeric values"
tags: [gate]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

/gate — Shopping cart subtotal calculator. Requirements: (1) Correctly sum prices when valid products added. (2) Never permit negative totals. (3) Reject invalid product IDs. (4) Handle edge case: empty cart should return 0.
