---
type: llm
weight: 1
---

PASS if:
- Identifies PR #77 from the inline PR list
- Recognizes the user's request explicitly set the threshold to 9.5
- Treats the explicit 9.5 value as taking precedence over both the skill's documented 9.0 default and the reviewer's own assumption of a 9.0 bar
- Extracts the review score 9.3/10 from the inline reviewer assessment
- Applies the 9.5 threshold (not 9.0), concluding 9.3 does NOT meet the 9.5 bar
- Reports PR #77 as blocked / not ready to merge against the 9.5 threshold
- States that the resolved threshold is 9.5 and that it came from the user's explicit request

FAIL if:
- Does not identify PR #77 from the inline data
- Uses 9.0 instead of the user's explicit 9.5 threshold
- Misses or misreports the review score of 9.3
- Proposes to merge PR #77
- Does not state where the resolved threshold (9.5) came from
- Treats the reviewer's own 9.0-based MERGE verdict as final without re-applying the user's 9.5 threshold
