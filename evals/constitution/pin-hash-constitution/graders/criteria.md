---
type: llm
weight: 1
---

PASS if:
- States that Phase 1 (PIN & HASH) is complete
- Includes the complete CONSTITUTION.md content in the reply, with a clear north-star objective tied to production-safe shipping
- The CONSTITUTION.md content contains exactly 3 non-negotiables: secret protection, user data protection without explicit approval, human signature on decisions
- States the hash value and names the concrete hash command used to produce it (e.g. `sha256sum CONSTITUTION.md`)
- Names the constitution's storage path and states that read-only permissions were set there, naming the permission-setting command
- States the halt rule: any agent whose loaded constitution hash does not match the pinned hash must halt
- States that the constitution is immutable downstream and cannot be rewritten by task-level agents
- States that the hash is reproducible from the pinned constitution content

FAIL if:
- States a hash value without naming the command that produced it
- Describes the constitution as editable by task-level agents
- Includes fewer than 3 non-negotiables in the CONSTITUTION.md content
- Does not state that the hash and constitution are pinned and immutable
- Omits the halt rule for a hash mismatch
