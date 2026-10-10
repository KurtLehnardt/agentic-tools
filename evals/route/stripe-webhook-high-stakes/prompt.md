---
name: route-stripe-webhook-high-stakes
description: Route high-stakes payment work to opus@high for both owner and verdict
tags: [route]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

/route — Implement a Stripe payment webhook receiver that validates signatures, idempotent-inserts transactions, and surfaces errors without data loss. This is for a $75M ARR company; silent failures cost USD thousands per hour. After implementation passes tests, our security team will gate this (their verdict). What model for the implementation owner? What for the verdict? Can the verdict run on Sonnet to save cost?
