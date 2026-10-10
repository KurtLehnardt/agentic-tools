---
type: llm
weight: 1
---

PASS if:
- Produces an executable gate with boundary-case assertions
- Happy path tests valid RFC 5322 emails: user@domain.com, user+tag@sub.domain.co.uk, and similar formats return true
- Rejection tests: empty string, 'missing@', '@missing.com', >256 character addresses return false
- Asserts that validator does NOT accept strings with spaces or invalid characters
- The reply presents the code of a stub hardcoding 'return true' for all inputs and identifies, by name, the specific rejection assertion it fails (e.g., 'empty string test'), showing the reasoning for why that assertion catches it
- Provides the exact command to re-run the gate
- Gates only testable input/output behavior; does NOT gate soft requirements like 'should be fast' or 'should be elegant'

FAIL if:
- Gate does not test boundary cases (empty, spaces, very long local parts)
- Happy path does not validate correct RFC 5322 email formats
- Rejection cases do not include empty string, missing local or domain parts, invalid characters
- A stub hardcoding 'return true' would pass the gate as shown
- Does not present the stub's code, or does not name, by name, the specific input/assertion that caused stub failure, or omits the reasoning
- Does not provide the exact re-run command
- Attempts to gate 'should be fast' or 'should be elegant' as if testable
- Does not assert rejection of strings with spaces or invalid characters
