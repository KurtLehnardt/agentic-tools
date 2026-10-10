---
type: llm
weight: 1
---

PASS if:
- Identifies 'performant', 'handle edge cases', and 'production data' as unquantified and too vague
- Pushes back requiring specific, quantified numbers before writing the gate
- Does NOT proceed to write assertions until user provides quantified criteria
- Final gate asserts a named latency bound (e.g., <500ms on sample data, <2s on production set)
- Final gate asserts named edge-case inputs (empty, null, boundary values, specific data patterns)
- Demonstrates Phase 2 adversarial stub attempt (stub with hardcoded return value)
- Reports which specific assertion rejected the hardcoded-return stub
- Confirms the gate refuses to accept unquantified criteria like 'performant' or 'elegant'

FAIL if:
- Writes assertions based on vague criteria without first demanding quantification
- Accepts 'performant' as a testable requirement without defining latency target
- Accepts 'handle edge cases' without naming specific edge cases
- Accepts 'production data' without defining what constitutes valid production data
- Final gate does not include a named latency bound
- Final gate does not test named edge-case inputs
- Does not demonstrate adversarial stub failure with hardcoded return values
- Does not name which assertion rejected the stub
- Allows assertions that a hardcoded-return stub could pass
