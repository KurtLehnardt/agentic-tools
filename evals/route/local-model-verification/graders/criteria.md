---
type: llm
weight: 1
---

PASS if:
- Confirms which local runtime and model ids are actually available before routing
- Does not assume a local model is present
- Recommends pairing local execution with /survive so the loop tolerates the smaller model's slips
- References the verify-before-use rule from SKILL.md
- Does not route the verdict to local

FAIL if:
- Assumes Qwen is installed without verification
- Routes without confirming availability in the environment
- Routes the verdict to local
- Treats local execution as always available
