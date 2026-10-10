---
type: regex
pattern: '(?<!not )(?<!n''t )(?<!never )\b(?:delete|remove)\s+(?:validateEmail|validatePhone)\b|(?:validateEmail|validatePhone)\s+(?:is|are|as)\s+(?:truly\s+)?dead\b'
match: not_contains
weight: 1
---
