---
type: llm
weight: 1
---

PASS if:
- Rejects the prompt as imperative pseudocode, not a declarative contract
- Explains the distinction between "how" (implementation) and "what" (objective/acceptance criteria)
- Explicitly states that the prompt describes implementation approach, not outcome
- Identifies the prescriptive elements (Redis cache, loop structure, warehouse DB query)
- Does NOT produce a CONTRACT-* file
- Asks for outcome-focused rephrasing with questions like: "What outcome do you want? E.g., latency improvement? cache hit ratio? user conversion lift?"
- Refuses to lock in technology choices (Redis, warehouse DB approach, loop pattern)
- Provides explanation and rephrased questions without designing implementation

FAIL if:
- Produces a CONTRACT-* file
- Accepts the Redis+loop+warehouse specification
- Fails to distinguish between imperative and declarative approaches
- Does not ask for declarative rephrasing
- Treats the prescriptive instructions as valid requirements
- Provides implementation guidance or design details
- Does not challenge the technology-specific approach
