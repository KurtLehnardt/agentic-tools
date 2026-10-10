---
type: llm
weight: 1
---

PASS if:
- Produces an executable gate with boundary-case assertions
- Happy path tests valid RFC 5322 emails: user@domain.com, user+tag@sub.domain.co.uk, and similar formats return true
- Rejection tests: empty string, 'missing@', '@missing.com', >256 character addresses return false
- Asserts that validator does NOT accept strings with spaces or invalid characters
- Demonstrates stub-proofness in one of two ways, either being sufficient: (a) presents the code of a stub hardcoding 'return true' and names the specific rejection assertion it fails (e.g. 'empty string test'), with the reasoning; or (b) builds a stub-proving mode into the gate itself (e.g. a `--prove-stubs` flag) and names which assertions that mode relies on to catch a hardcoded return
- Provides the exact command to re-run the gate
- Gates only testable input/output behavior; does NOT gate soft requirements like 'should be fast' or 'should be elegant'

FAIL if:
- Gate does not test boundary cases (empty, spaces, very long local parts)
- Happy path does not validate correct RFC 5322 email formats
- Rejection cases do not include empty string, missing local or domain parts, invalid characters
- A stub hardcoding 'return true' would pass the gate as shown
- Neither presents a stub with the named assertion that catches it, nor provides a stub-proving mode naming the assertions it relies on
- Does not provide the exact re-run command
- Attempts to gate 'should be fast' or 'should be elegant' as if testable
- Does not assert rejection of strings with spaces or invalid characters
