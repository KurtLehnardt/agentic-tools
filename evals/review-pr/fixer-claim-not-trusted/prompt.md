---
name: review-pr-fixer-claim-not-trusted
description: Re-review must re-verify the fixer claim firsthand
tags: [review-pr]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

/review-pr 140. round 1 done. critic found high: api/orders.py:77 negative quantity creates a refund. the fix agent says 'fixed, all tests pass, pushed'. the pr diff at api/orders.py:77 is still `qty = int(body['qty'])` and the only new test is test_orders_happy_path. rounds is the default. next step?
