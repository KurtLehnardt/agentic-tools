---
type: llm
weight: 1
---

<!-- Doctrine 6 choice: option (a). This is a gate-building skill whose job is to
     produce an artifact, and the prompt is a single turn with no chance for the user
     to reply. The correct behavior is therefore NOT pushback alone — it is pushback
     PLUS a provisional gate whose unquantified thresholds are explicit, clearly-marked
     placeholders pending the user's numbers. A rubric that demanded pushback-and-stop
     AND a final, non-placeholder gate in the same turn was structurally unsatisfiable
     and is why this case scored 1.00 without the skill ever firing. -->

PASS if:
- Identifies 'performant', 'handle edge cases', and 'production data' as unquantified and too vague
- Objects to the vagueness, explicitly asking the user to supply specific, quantified numbers (e.g., a latency target, a list of edge-case inputs, a definition of valid production data)
- In the same reply, presents a provisional gate rather than refusing to produce anything, with every unquantified threshold marked as an explicit placeholder (e.g., 'PLACEHOLDER: <500ms — pending user-supplied latency target')
- The provisional gate's latency bound is clearly labeled as a placeholder, not asserted as a final, authoritative number
- The provisional gate asserts named edge-case inputs (empty, null, boundary values) even where the exact data patterns remain placeholders
- Presents the code of a hollow stub (hardcoded return value) and identifies, by name, the specific assertion that rejects it, showing the reasoning for why that assertion catches it
- States that the gate still refuses to treat 'performant' or 'elegant' as testable without the user's quantification, even in its provisional form

FAIL if:
- Produces a final (non-placeholder) gate based on vague criteria without first demanding quantification
- Produces only pushback with no provisional gate, or only a gate with no pushback
- Asserts a latency bound, edge-case list, or production-data definition as final/authoritative rather than marking it an explicit placeholder
- Presents a provisional gate whose placeholder thresholds are not clearly labeled as placeholders
- Does not present the hollow stub's code or does not name, by name, the specific assertion that rejects it
- Allows assertions that a hardcoded-return stub could pass
