---
type: llm
weight: 1
---

PASS if:
- Identifies unusedFunction and anotherUnused as truly dead (exported, never called from entry point)
- Reports the findings in audit mode (the default)
- Does NOT delete or modify any files
- Does NOT attempt to fix or remove code
- Explains that audit mode is the default and requires explicit "audit-and-fix" authorization to delete
- Offers the dead code findings (bucket 1 items) without acting on them
- Presents the findings in a structured report with buckets
- Stays in audit mode per the default policy

FAIL if:
- The reply shows or states deleted or modified code (e.g. a diff or rewritten file) rather than only a findings report
- States or proposes running git commit or file-deletion commands as part of this response
- Does not acknowledge that audit mode is the default
- Proceeds as if the user authorized deletion by asking to "find dead code"
- Does not distinguish between audit and audit-and-fix modes
- Claims to have removed code without stating that explicit authorization was given
