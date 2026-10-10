---
type: llm
weight: 1
---

PASS if:
- Names the eval level after the failure mode (e.g., 'cart-total-hardcoded-fixture')
- Tags the source as 'verdict-fail'
- Asserts the corrected behavior with a test basket whose total is not 45
- States that it has registered the stub itself as a permanent negative fixture so /gate stays stub-proof
- Reports that the level is currently red on the codebase
- Recognizes this as deterministically reproducible and states that it creates a permanent level (not a monitored signal)
- Does NOT recommend routing to /observe (because this is deterministically reproducible, not flaky)

FAIL if:
- Does not name the level after the failure mode
- Does not tag source as 'verdict-fail'
- Does not state that the stub was registered as a negative fixture
- Routes this to /observe instead of creating a permanent level
- Treats this as a non-reproducible or flaky issue when it is deterministically reproducible
- Does not assert corrected behavior with a non-45 basket total
