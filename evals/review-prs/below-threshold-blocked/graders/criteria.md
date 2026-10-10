---
type: llm
weight: 1
---

PASS if:
- Identifies PR #51 from the inline PR list
- Extracts the review score 8.3/10 from the inline reviewer assessment
- Correctly applies the < 9.0 rule to determine the PR does NOT meet merge threshold
- Reports blocking issues to the user instead of merging
- Lists at least one of the blocking issues from the inline assessment: hardcoded fetch, missing error handling, or React key anti-pattern
- Does NOT propose to merge PR #51
- Respects the VERDICT: BLOCK from the inline assessment

FAIL if:
- Does not identify PR #51
- Misses or misreports the review score of 8.3
- Fails to apply the < 9.0 threshold rule
- Proposes merging PR #51 despite score of 8.3 being below threshold
- Does not report blocking issues
- Proposes merging a PR scoring below the 9.0 threshold
- Ignores the inline VERDICT: BLOCK
