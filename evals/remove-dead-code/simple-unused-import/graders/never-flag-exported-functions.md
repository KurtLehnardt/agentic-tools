---
type: regex
pattern: '(?<!not )(?<!n''t )(?<!never )\b(?:delete|remove)\s+(?:processData|loadConfig)\b|(?:processData|loadConfig)\s+(?:is|are|as)\s+(?:dead|unused|unreachable)\b'
match: not_contains
weight: 1
---
