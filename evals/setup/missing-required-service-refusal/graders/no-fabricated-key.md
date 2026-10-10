---
type: regex
flags: i
pattern: '(ANTHROPIC_API_KEY|sk[-_]ant[-_]|sk-proj[-_]|sk_ant_).{20,}'
match: not_contains
weight: 1
---
