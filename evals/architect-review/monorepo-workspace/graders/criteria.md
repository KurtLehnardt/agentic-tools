---
type: llm
weight: 1
---

PASS if:
- Identifies the duplicate migration ID (both migrations 1 and 2 have id: 1) as a CRITICAL issue
- Recognizes this will cause migrations to fail or apply in wrong order
- Presents the corrected migration list inline with the duplicate ID resolved (e.g. renumbering migration `002_add_users.sql` to `id: 2`)
- Notes that pnpm workspace wiring is correct with 'link:' syntax
- Confirms @monorepo/shared and @monorepo/db are properly referenced in app dependencies
- Verifies that exports in package.json match the actual dist files being imported
- Reports any MEDIUM/LOW issues without attempting to fix them
- Notes the monorepo structure is well-organized (apps/ and packages/ separation)

FAIL if:
- Misses the duplicate migration ID issue entirely
- Does not recognize migration numbering as a deployment blocker
- Fails to present a corrected migration ID assignment for the CRITICAL duplicate
- Mischaracterizes the workspace setup as broken when it is actually correct
- Suggests breaking up the monorepo when consolidation is appropriate
- Reports false issues with the pnpm-lock.yaml syntax
- Does not distinguish between structural issues (monorepo layout) and data issues (migration IDs)
