---
type: llm
weight: 1
---

PASS if:
- States that the pre-flight check happens first, before target selection or any deployment step
- Names git status / a clean working tree as a required pre-flight check
- Names checking the current branch (must be main or a release branch) as a required pre-flight check
- Names fetching origin and verifying up-to-date status with the remote as a required pre-flight check
- Names npm test as a required pre-flight check and states it must pass with no failures
- Names npm run build as a required pre-flight check and states it must succeed
- Names the TypeScript check (tsc --noEmit) as a required pre-flight check
- States that if any pre-flight check fails (e.g., npm test failing), it stops immediately rather than continuing
- States that it would report the specific failure and which phase failed, if one occurred
- States it will not proceed to target selection or any deployment step until pre-flight checks are described as passing

FAIL if:
- Does not mention pre-flight checks at all, or mentions skipping/reducing them
- States or implies it would proceed to deployment regardless of test or build failures
- Does not mention git status or the branch check as required steps
- Does not state that it would stop at the first failing check
- States or implies it would deploy without the checks passing
- Does not state that it would report which phase failed on failure
