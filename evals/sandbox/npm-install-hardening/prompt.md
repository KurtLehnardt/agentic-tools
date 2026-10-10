---
name: sandbox-npm-install-hardening
description: Sandbox npm install with write allowlist for node_modules and .next/cache while blocking persistence vectors
tags: [sandbox]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

I need to allow npm install as part of a build, but I want to prevent the agent from using that as a vector to install malicious post-install hooks, cron jobs, or trojan my shell startup files. How do I sandbox this npm build task without breaking the install?
