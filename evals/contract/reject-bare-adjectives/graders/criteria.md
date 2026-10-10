---
type: llm
weight: 1
---

PASS if:
- Rejects the prompt as containing bare adjectives without measurable thresholds
- Explicitly identifies the adjectives used ('fast', 'clean', 'secure', 'safe', 'production ready')
- States "Cannot proceed with adjectives alone" or equivalent refusal
- For each adjective, provides example transformation or asks clarifying question
- Example questions match pattern: "fast" → latency target?, "clean" → code style/coverage/UX conversion?, "secure" → threat model/PCI-DSS/audit checklist?
- Offers partial contract framework for user to complete once thresholds are provided
- Does NOT produce a CONTRACT-* file
- Requests specific measurable answers (numbers, thresholds, commands)

FAIL if:
- Produces a CONTRACT-* file with acceptance criteria
- Accepts any bare adjective without quantifying it
- Produces acceptance criteria containing vibes or unverifiable claims
- Does not flag the vagueness in the request
- Fails to ask clarifying questions
- Does not explicitly reject the prompt
- Provides generic criteria like "users will feel protected" without measurement mechanism
