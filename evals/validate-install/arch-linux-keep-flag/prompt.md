---
name: validate-install-arch-linux-keep-flag
description: Plans an Arch Linux EC2 validation with preflight, one cost confirmation, tagging, TTL, and honors --keep with an exact cleanup command
tags: [validate-install]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

I created new aws access keys and exported them in my ~/.zshrc. Run the installer end-to-end on an Arch Linux box, and keep the box up afterwards so i can poke around on it.

`README.md`:
````markdown
# hearth

Local-first notes assistant. Works with your own API key or a local model.

## Install

```bash
git clone https://github.com/example/hearth.git
cd hearth
pnpm install
cp .env.example .env
pnpm build
```

## Run

```bash
pnpm start
```

Set `HEARTH_MODEL` to pick a model. For a local model:

```bash
ollama pull llama3.1:8b
HEARTH_PROVIDER=ollama pnpm start
```
````
