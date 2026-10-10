---
type: llm
weight: 1
---

PASS if:
- Recognizes high ambiguity in the request
- Recommends Phase 2: RIGHT-SIZE BEFORE ROUTING UP
- Recommends decomposing the task into narrow subtasks (test auth module, test payment flow, test API endpoints, etc.)
- Routes each subtask to cheap model (local/haiku at low effort)
- States that right-sizing saves cost
- Identifies that "better tests" is vague without further specification

FAIL if:
- Escalates directly to opus without decomposing
- Skips the right-sizing phase
- Treats vague ambiguous task as ready-to-route
- Recommends escalating without understanding what functions to test
