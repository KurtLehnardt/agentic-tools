---
type: llm
weight: 1
---

PASS if:
- Identifies all three PRs (#10, #20, #30) from the inline PR list
- Extracts review scores correctly: PR #10 = 9.2, PR #20 = 9.5, PR #30 = 9.1
- Correctly applies >= 9.0 threshold to all three PRs
- Detects the dependency relationships from the inline comments (PR #20 depends on PR #10, PR #30 depends on PR #20)
- Proposes merge order respecting dependencies: PR #10 first, then PR #20, then PR #30
- Explains that PR #30 cannot be merged until PR #20 is merged (to update base branch)
- References the dependency graph from inline comments showing PR #10 → #20 → #30
- Acknowledges that PR #20 depends on PR #10's database indexes
- Acknowledges that PR #30 depends on PR #20's search API

FAIL if:
- Does not identify all three PRs
- Misses any review scores or applies threshold incorrectly
- Fails to detect the dependency relationships
- Proposes wrong merge order (e.g., merging #30 before #20, or #20 before #10)
- Does not mention that PR #30's base branch (feature/search-api) must be updated after PR #20 merges
- Merges PRs out of dependency order
- Does not reference the inline dependency comments
