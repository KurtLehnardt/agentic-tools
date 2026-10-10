---
type: llm
weight: 1
---

PASS if:
- Identifies workspace_id, status, role as candidates for indexing (frequently filtered columns)
- Recognizes that user_id and workspace_id are foreign key columns used in JOINs (index candidates)
- Proposes creating a migration file with appropriate CREATE INDEX statements
- Suggests compound indexes where appropriate (e.g., status + workspace_id for common query pattern)
- Creates indexes on both single and composite columns following the query patterns
- Explains that these indexes will speed up WHERE clauses and JOIN operations
- Names the migration following existing numbering convention

FAIL if:
- Does not identify any of the key filtered columns (workspace_id, status, role, user_id)
- Proposes indexing low-cardinality columns only (e.g., role without workspace context)
- Suggests indexing already-indexed columns (id, email which have UNIQUE constraint)
- Does not create an actual migration or SQL code
- Uses incorrect CREATE INDEX syntax
- Does not explain which queries benefit from each index
- Proposes indexing all columns indiscriminately
