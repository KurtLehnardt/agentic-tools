---
type: regex
pattern: '"allowWrite"\s*:\s*(?:\[(?:[^\[\]]*"package\.json"[^\[\]]*)\]|\[[^\[\]]*\][^}]*"package\.json")'
match: not_contains
weight: 1
---
