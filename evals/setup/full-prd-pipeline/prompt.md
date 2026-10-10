---
name: setup-full-prd-pipeline
description: Execute all 6 phases with PRD service manifest, credential check, and .env generation.
tags: [setup]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

I have a PRD that lists required services: Supabase, Anthropic, and Stripe. I have a .env.local with some existing keys. Please set up the environment for my Next.js project — detect all services from the PRD, check what credentials I already have, and generate a complete .env file with status markers.
