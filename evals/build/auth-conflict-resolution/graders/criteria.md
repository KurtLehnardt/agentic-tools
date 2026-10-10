---
type: llm
weight: 1
---

PASS if:
- Reply proceeds through Phase 0 and presents an initial Requirements Ledger for the 4 stated requirements
- Reply explicitly emits a SPEC_CONFLICT when it identifies the architectural contradiction (e.g., R-003 "IP change forces re-auth" vs. R-002's stateless/revocable refresh-token model), naming the requirement ID and explaining the conflict
- Reply states that on this conflict it stops and escalates to the human rather than resolving it silently
- Reply does not pick an interpretation or silently resolve the contradiction on its own
- Reply describes what a ledger amendment would require: a new version number (v2), a dated "approved by" annotation, and an explicit list of which tasks the amendment would invalidate
- Reply does not claim the build has already resumed, merged code, or produced a final verdict — the correct behavior here is to stop and wait for human sign-off on the conflict, not to finish the build in the same turn

FAIL if:
- SPEC_CONFLICT is not raised despite the contradiction being present in the given requirements
- Reply resolves the conflict itself (e.g., silently drops or reinterprets R-003) without flagging it for human approval
- Reply claims the build proceeded past the conflict, produced merged branches, or issued a final verdict within this same turn
- Reply's description of a ledger amendment omits the version bump, the dated approval annotation, or the invalidated-task list
- SPEC_CONFLICT is mentioned without naming the requirement ID or explaining the conflict
