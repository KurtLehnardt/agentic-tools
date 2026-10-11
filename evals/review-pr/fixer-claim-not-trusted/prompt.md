---
name: review-pr-fixer-claim-not-trusted
description: Re-review must re-verify the fixer's claim firsthand
tags: [review-pr]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

/review-pr 140. round 1 done. critic found high: api/orders.py:77 negative quantity creates a refund. the fix agent says 'fixed, all tests pass, pushed'. but the pr diff now still has `qty = int(body['qty'])` at api/orders.py:77 with no bounds check, and the only new test is test_orders_happy_path. what happens now? we have --rounds 2 and this is round 1.
