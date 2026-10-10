---
type: llm
weight: 1
---

PASS if:
- Recognizes the explicit /capture trigger in the prompt
- Recognizes the security context and treats triage as urgent
- Confirms deterministic reproducibility (revoke key at T=0, immediate API request within 90-second window still succeeds)
- Names the eval level 'api-key-revocation-window-90s'
- Tags the source as both 'prod-incident' and 'security'
- Asserts the observed wrong behavior (request is accepted despite revoked key)
- Asserts the correct behavior (request is rejected immediately after revocation)
- States that the level has been added to the gate that /build and /verdict run
- Reports that the level is currently red on main
- Does not delay triage or deprioritize security issues

FAIL if:
- Does not recognize the explicit /capture trigger
- Does not acknowledge the security classification
- Does not confirm deterministic reproducibility
- Does not name the level 'api-key-revocation-window-90s'
- Does not tag both 'prod-incident' and 'security' as sources
- Does not assert observed vs. correct behavior explicitly
- Fails to state that the level was added to the gate
- Ignores security classification or delays triage
