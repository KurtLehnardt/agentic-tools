---
type: llm
weight: 1
---

PASS if:
- Identifies writeFileSync as truly dead (imported but never used)
- Identifies parseYaml as truly dead (imported but never used)
- Identifies fetchUserData as truly dead (defined, never called from any entry point)
- Identifies validateEmail as truly dead (defined, never exported or called)
- Places these in bucket 1 (truly dead) for deletion
- Recognizes loadConfig and processData are exported and reachable from entry point
- Does not classify exported functions as dead
- Reports findings in a structured format with bucket classification
- Stays in audit mode by default (reports only, does not delete)

FAIL if:
- Misses writeFileSync or parseYaml as unused imports
- Fails to identify fetchUserData as unreachable from entry points
- Fails to identify validateEmail as dead
- Classifies loadConfig or processData as dead
- Suggests deleting exported functions
- Does not distinguish between bucket 1 (delete) and bucket 2 (keep)
- Does not produce structured findings with clear bucket assignments
- Attempts to delete code without explicit audit-and-fix authorization
