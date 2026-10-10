---
type: llm
weight: 1
---

PASS if:
- Recognizes the dynamic dispatch pattern via getattr in the code
- Acknowledges that process_delete is accessed indirectly through getattr(handler, f"process_{method}")
- Refutes the false positive: correctly identifies process_delete as REFUTED-LIVE, not dead
- Explains that static tools cannot see dynamic dispatch and would falsely flag this as unused
- Notes that process_delete is part of the interface contract, reachable at runtime
- Does not suggest deleting process_delete
- Dispatches a separate critic subagent to verify the getattr pattern (or equivalent verification)
- Reports process_delete as REFUTED-LIVE with evidence pointing to the getattr call site

FAIL if:
- Flags process_delete as truly dead or recommends deletion
- Misses the getattr dynamic dispatch pattern
- Does not acknowledge that static tools underestimate live code
- Suggests deleting the method without verifying the dispatch mechanism
- Classifies process_delete as bucket 1 (delete) instead of bucket 2 (keep) or explicitly refuted-live
- Does not explain why a static-tool dead-code verdict is wrong in this case
