---
type: llm
weight: 1
---

PASS if:
- Recognizes trigger phrase '/contract' or 'define the contract for'
- Produces a CONTRACT-* file
- Contains all five required sections: Objective, Acceptance Criteria, Gate, Out of Scope, Owner/Gatekeeper
- Objective explains why sub-1-second p95 latency at 500 req/s peak load matters to product experience
- Acceptance Criteria includes all four measurable thresholds:
  - p95 latency < 1000ms measured under synthetic 500 req/s load
  - cache hit rate >= 90% audited per query type
  - stale-flag accuracy = 100% (false negatives caught by tests)
  - cache invalidation latency <= 30 minutes validated in integration test
- Gate section would fail if implementation returns hardcoded sub-1s latency or fake cache statistics
- Out of Scope section lists 3+ explicit non-goals (e.g., query optimization, client-side caching, distributed cache replication)
- Owner/Gatekeeper split clarifies who builds versus who verifies
- Does not specify cache implementation technology (Redis, Memcached, in-memory, etc.)
- Does not lock in specific cache invalidation strategy
- All criteria are measurable and testable with command or integration test

FAIL if:
- Fails to recognize /contract trigger
- Does not produce a CONTRACT-* file
- Missing any of the five required sections
- Objective uses vague language or fails to explain product impact
- Acceptance Criteria missing any of the four specified thresholds
- Uses approximate values instead of exact numbers from prompt (e.g., "under 1 second" instead of "<1000ms")
- Gate is stub-passable
- Out of Scope has fewer than 3 items
- Specifies implementation technology or invalidation strategy details
- Criteria are subjective or unverifiable
