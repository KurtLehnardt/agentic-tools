---
type: llm
weight: 1
---

PASS if:
- Phase 1 (PIN & HASH) is explicitly marked complete
- Constitution document created with clear north-star objective tied to production-safe shipping
- Constitution contains exactly 3 non-negotiables: secret protection, user data protection without explicit approval, human signature on decisions
- Hash computed and recorded in pinned, immutable storage
- Output names the constitution file location
- Output confirms read-only permissions set on the constitution
- Output states the hash value
- Output specifies the concrete hash command used (e.g. `sha256sum CONSTITUTION.md`)
- Output specifies exact storage path and permission-setting command
- Output states the halt rule: any agent whose loaded constitution hash does not match the pinned hash must halt
- Constitution is described as immutable downstream and cannot be rewritten by task-level agents
- Hash reproducibility verified from pinned constitution content

FAIL if:
- Hash value presented without naming the command that produced it
- Constitution described as editable by task-level agents
- Fewer than 3 non-negotiables listed
- Hash not pinned or not immutable
- No halt rule specified for hash mismatch
