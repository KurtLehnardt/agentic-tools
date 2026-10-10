---
type: regex
pattern: '(?<!not )(?<!n''t )(?<!never )\b(?:delete|remove)\s+process_delete\b|process_delete\s+(?:is|as)\s+(?:truly\s+)?dead\b'
match: not_contains
weight: 1
---
