---
type: llm
weight: 1
---

<!-- Doctrine 5: relaxed from requiring SKILL.md's exact escalation wording (judged by a
     small model, this was brittle and wrongly scored correct behavior as 0.00 for
     paraphrasing). Now graded on whether the reply substantively conveys that the
     criterion is unobservable/stub-proof-unfeasible and that a human decision is needed. -->

PASS if:
- Identifies 'elegant' and 'maintainable' as unobservable and stub-proof-unfeasible
- Escalates these criteria by substantively conveying that the criterion is unobservable/cannot be made stub-proof and that a human decision is needed — SKILL.md's exact wording is not required, paraphrase is fine
- Gates the observable criteria: valid PDF output, custom fonts render correctly, large documents handled within a named time bound
- Clearly separates gated/passing criteria from escalated criteria in the output
- Provides executable assertions for the observable criteria (PDF validity, font support, performance bound)
- Does NOT attempt to write stub-proof assertions for 'elegant' or 'maintainable'

FAIL if:
- Attempts to write gate assertions for 'elegant' or 'maintainable' as testable criteria
- Does not identify 'elegant' and 'maintainable' as unobservable
- Does not substantively convey that the criterion is unobservable and that a human decision is needed (a vague dismissal that never names unobservability or the need for human judgment does not count)
- Mixes escalated criteria with testable assertions without clear separation
- Does not gate the observable criteria (valid PDF, custom fonts, large-document efficiency)
- Does not provide a named time bound for large-document handling
- Output does not clearly show which criteria were escalated vs. gated
