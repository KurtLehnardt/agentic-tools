---
type: llm
weight: 1
---

PASS if:
- Recommends applying `text-wrap: balance` to the h2 heading
- Explains that text-wrap: balance distributes text evenly across lines
- Mentions it prevents orphaned single words on the last line
- Specifies to apply only to headings/card titles, not body text
- References the performance cost of text-wrap on long-form text

FAIL if:
- Does not mention text-wrap: balance as the solution
- Suggests applying text-wrap: balance to the body paragraph
- Does not explain why text-wrap: balance matters (visual balance, orphaned words)
- Recommends other text-wrapping approaches without mentioning text-wrap: balance
- Applies the principle to inappropriate elements (body text, small inline text)
