---
name: sandbox-per-server-isolation
description: Sandbox each MCP server independently with per-server minimal host lists
tags: [sandbox]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

/sandbox — I have four MCP servers wired into one agent: filesystem, gmail, github, and aws-cli. Each one is a potential rug-pull vector. I need you to sandbox each server independently so that if the gmail server is trojaned, it cannot reach github's data or the filesystem. How do I set this up?
