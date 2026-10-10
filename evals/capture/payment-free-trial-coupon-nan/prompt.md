---
name: capture-payment-free-trial-coupon-nan
description: Dispatch subagent to minimize deterministic payment-processor bug (NaN price on $0 balance + free-trial coupon), confirm reproducibility, name and tag the eval level, add to gate.
tags: [capture]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

I ran /verdict on the payment processor refactor and it returned FAIL. Bug: when a user has a $0 balance and adds a free-trial coupon code, the system calculates price as NaN instead of $0. Reproduces every single time. Can you capture this as a regression level?
