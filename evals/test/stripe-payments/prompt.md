---
name: test-stripe-payments
description: Comprehensive test suite for critical payment processing system
tags: [test]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

add tests for my payment processing system. the main file is lib/payments/stripe.ts which handles subscription creation, charge processing, and webhook signature validation. it talks to Stripe API and writes to a Postgres DB. this is the most critical module in the app, so it needs solid coverage. Include the complete test file(s) in your reply.
