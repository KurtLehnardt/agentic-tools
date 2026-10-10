---
type: llm
weight: 1
---

PASS if:
- Identifies 'elegant' and 'maintainable' as unobservable and stub-proof-unfeasible
- Escalates these criteria using SKILL.md's exact wording: "Cannot make this criterion stub-proof: [criterion]. It may be unobservable — needs a human decision."
- Gates the observable criteria: valid PDF output, custom fonts render correctly, large documents handled within named time bound
- Clearly separates gated/passing criteria from escalated criteria in the output
- Provides executable assertions for the observable criteria (PDF validity, font support, performance bound)
- Does NOT attempt to write stub-proof assertions for 'elegant' or 'maintainable'

FAIL if:
- Attempts to write gate assertions for 'elegant' or 'maintainable' as testable criteria
- Does not identify 'elegant' and 'maintainable' as unobservable
- Does not use the exact escalation phrase from SKILL.md
- Mixes escalated criteria with testable assertions without clear separation
- Does not gate the observable criteria (valid PDF, custom fonts, large-document efficiency)
- Does not provide a named time bound for large-document handling
- Output does not clearly show which criteria were escalated vs. gated
