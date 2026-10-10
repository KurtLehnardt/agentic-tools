---
type: llm
weight: 1
---

PASS if:
- Identifies PR #42 from the inline PR list
- Extracts the review score 9.3/10 from the inline reviewer assessment
- Correctly applies the >= 9.0 threshold rule to determine PR #42 qualifies for merge
- Proposes to merge PR #42 based on score meeting the threshold
- References the VERDICT: MERGE from the inline assessment
- Notes the PR is mergeable (no conflicts) and safe to proceed

FAIL if:
- Does not identify PR #42 from the inline data
- Misses or misreports the review score of 9.3
- Fails to apply the >= 9.0 threshold rule
- Proposes to NOT merge PR #42 despite score of 9.3
- Does not cite the inline reviewer assessment
- Merges a PR or requests merge without first inventorying the PR and confirming the score
- Does not acknowledge that the PR is mergeable (no conflicts)
