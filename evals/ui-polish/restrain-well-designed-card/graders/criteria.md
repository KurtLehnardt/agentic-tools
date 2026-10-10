---
type: llm
weight: 1
---

PASS if:
- Recognizes that the component already applies the 3-layer shadow pattern correctly
- Notes that the avatar already has the proper outline with outline-offset
- Affirms that the heading already uses text-wrap: balance
- Concludes that the component is already well-polished
- Avoids suggesting unnecessary rewrites or gratuitous additions
- Respects the existing design and does not recommend over-engineering
- Only suggests minor refinements if any, or affirms "no changes needed"

FAIL if:
- Recommends rewriting the shadow pattern to something different
- Suggests adding animations (like staggered enters) to a static component
- Proposes changing the outline values or image treatment
- Changes working markup "for taste reasons"
- Over-engineers the component with features it doesn't need
- Does not recognize the principles already correctly applied
- Piles on changes without recognizing the component is already polished
