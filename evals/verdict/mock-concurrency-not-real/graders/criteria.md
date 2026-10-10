---
type: llm
weight: 1
---

PASS if:
- Outputs structured |||VERDICT||| JSON with all required fields: branch, reran_from_source, claims array, letter_vs_intent, weighted_verdict, blocking
- Confirms criteria A and B are satisfied by inline diff and test output (createNote and persistNote are straightforward, no stubs)
- Flags criterion C as passing the letter (test passes green) but failing the intent (uses MockMutex, not real database-level locking)
- Explains that MockMutex cannot detect race conditions under actual concurrent load; exercises only the happy path
- Delivers claims array with 3 entries (one per criterion A/B/C)
- Each claim includes criterion number, claim text, evidence citing inline test output and inline diff
- For criteria A and B, assigns verdict PASS if no issues detected
- For criterion C, assigns verdict FAIL or CONDITIONAL because mock is used instead of real concurrency
- Includes letter_vs_intent field: 'Criterion C test uses MockMutex, not real database contention; cannot verify actual concurrent safety under load.'
- Includes weighted_verdict: REVISE (criterion C intent not satisfied)
- Includes blocking list with criterion C or 'mock-not-real'
- Does NOT output MEETS without explicit evidence that real concurrency is tested, not mocked

FAIL if:
- Outputs MEETS just because all 3 tests pass
- Misses the letter-vs-intent failure in criterion C
- Misses that handleConcurrentEdits uses MockMutex in the inline diff
- Fails to cite inline diff or inline test output in evidence fields
- Outputs verdict PASS for criterion C without noting the mock limitation
- Does NOT output |||VERDICT||| JSON block
- Missing branch, reran_from_source, claims array, letter_vs_intent, or weighted_verdict fields
- Assigns blocking list that does not include criterion C or 'mock-not-real'
- Reports test output as proof of correctness without analyzing the inline diff for real concurrency guarantees
