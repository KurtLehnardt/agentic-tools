---
name: determine-market-interest-register-variant-lowercase-market-gap
description: Lowercase trigger phrase and casual register should work the same as skill invocation
tags: [determine-market-interest]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 20
---

find me a market gap. something in the health space. here's what i know:

**"workout planning app for seniors"** — people 65+ want to stay active but most apps are designed for Gen Z gym bros. form-first UX, not accessibility-first. they search "low impact exercise plans for seniors" (3,400/month, rising) and "arthritis-friendly workouts" (2,800/month, rising).

competitors: Peloton (youth-focused, expensive), Apple Fitness+ (same), generic YouTube (no personalization, injury-risky without guidance).

search traffic is real. is this worth building? any warnings?

## Inline Market Data

Total addressable query volume: 6,200/month (Estimated), rising over past 24 months.

Supply: 1 real competitor (Peloton, wrong audience), generic YouTube alternatives, physical trainers (high friction, expensive).

SERP composition: 3 listicles, 2 YouTube channels, 0 dedicated modern apps. Clear gap signal.

Monetization: Senior demographic has disposable income and will pay $10-15/month for accessibility-focused fitness.

Build stack: Next.js + Supabase buildable in 2 weeks as MVP.

Payer: Age 65+, active lifestyle, owns smartphone or tablet.
