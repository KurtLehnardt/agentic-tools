---
name: validate-install-readme-unstated-assumptions
description: Extracts README steps literally and flags unstated prerequisites and undocumented env vars
tags: [validate-install]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

does the README install work on a fresh machine? before spinning anything up, pull the install steps out of it and tell me what a stranger would trip on.

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
