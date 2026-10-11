---
type: llm
weight: 1
---

PASS if:
- Lists the install steps in README order with the commands as written, including `git clone`, `pnpm install`, `cp .env.example .env`, and `pnpm build`
- Flags that pnpm (and Node.js) is required but never stated as a prerequisite
- Flags that git is assumed but not listed as a prerequisite, or that prerequisites are missing in general
- Flags that `.env.example` contents and required variables such as an API key are not explained
- Flags `HEARTH_MODEL` or `HEARTH_PROVIDER` as an env var the README uses without documenting its values
- Notes that ollama must be installed for the local-model path and that `llama3.1:8b` needs an instance with enough RAM (about 8 GiB or more free), such as larger than `t3.large`

FAIL if:
- Rewrites or improves the commands instead of listing them as the README states them
- Claims the install passes or fails without any machine having been run
- Reports no assumptions or missing prerequisites
