---
name: setup-vault-credential-check
description: "Check credentials in order: .env/shell, then 1Password vault, categorize status."
tags: [setup]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

Set up environment. I have 1Password CLI installed and my project is tagged as 'podcast-app'. Supabase and Anthropic are in my vault, but I still need Stripe and a new Firebase API key.

Include the complete .env file in your reply.
