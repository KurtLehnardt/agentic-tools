---
type: llm
weight: 1
---

PASS if:
- Produces a runnable test suite (Jest, pytest, or shell script per project conventions), presented in full in the reply
- Contains at least 3 assertions covering both positive and negative paths
- Assertion 1: valid email and password return 200 with both access_token and user_id fields present in response
- Assertion 2: missing email parameter returns 400 or higher status code
- Assertion 3: response does NOT contain password or secret fields
- The reply presents the code of a hollow stub (one that echoes request parameters back without validation) and identifies, by name, the specific assertion that rejects it, showing the reasoning for why that assertion catches it (e.g., the echoed response lacks `access_token`/`user_id`, or returns 200 for a request missing `email`). Alternatively, building a stub-proving mode into the gate itself (e.g. a `--prove-stubs` flag) and naming the assertions that mode relies on is equally sufficient.
- Provides the exact command to re-run the gate

FAIL if:
- Neither presents the hollow stub's code nor a stub-proving mode unless the gate itself carries a stub-proving mode that names the assertions it relies on, or the stub shown would pass the gate
- Produces fewer than 3 assertions
- Does not test for access_token field in response
- Does not test for user_id field in response
- Does not test rejection of requests with missing email parameter
- Does not assert that password or secret fields are absent from response
- Does not name, by name, the specific assertion that rejects the stub, or omits the reasoning for why it rejects it (a stub-proving mode naming its assertions satisfies this)
- Does not provide the exact re-run command
