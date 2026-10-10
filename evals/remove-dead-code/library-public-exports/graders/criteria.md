---
type: llm
weight: 1
---

PASS if:
- Correctly identifies this as a library (package.json with exports, published to npm)
- Recognizes that validateEmail and validatePhone are public exports and entry points
- States that public exports must not be deleted (external consumers depend on them)
- Acknowledges that validateEmail and validatePhone appear unused internally but are live via external callers
- Correctly identifies _applySchema as internal-only (marked with _) but NOT dead (used by transformData)
- Places validateEmail, validatePhone in bucket 2 (keep—public API)
- Places _applySchema in bucket 2 (keep—used by internal function, part of the interface contract)
- Does not suggest deleting any exported functions
- Explains the library-vs-app distinction clearly

FAIL if:
- Treats the library as an app and flags public exports as dead
- Suggests deleting validateEmail or validatePhone
- Misses that transformData depends on _applySchema
- Flags _applySchema as truly dead
- Does not acknowledge external consumers of public exports
- Does not distinguish between library roots and app entry points
