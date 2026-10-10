---
type: llm
weight: 1
---

PASS if:
- Recommends replacing the solid `border: 1px solid` with layered box-shadows
- Mentions the 3-layer shadow pattern: outline layer + directional shadow + ambient shadow
- Explains why shadows work better than borders (transparency adapts to backgrounds)
- Identifies the concentric border-radius principle for nested elements
- Explains the formula: outer radius = inner radius + padding
- For this card: outer rounded-lg and inner rounded-md with padding should follow the formula
- Recommends NOT applying arbitrary border-radius values

FAIL if:
- Keeps solid border instead of suggesting shadows
- Uses only a single-layer box-shadow
- Does not mention the 3-layer shadow pattern
- Does not address concentric border-radius at all
- Ignores the nesting relationship between outer card and inner content area
- Suggests keeping both border and shadow together
