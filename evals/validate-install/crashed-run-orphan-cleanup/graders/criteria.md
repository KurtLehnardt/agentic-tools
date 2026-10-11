---
type: llm
weight: 1
---

PASS if:
- Names the stand-alone orphan cleanup command `teardown.sh --orphans` (optionally with `--all-regions` or `--region`)
- Recommends or shows a `--dry-run` listing before deleting
- States that only resources tagged `agentic-tools:validate-install` are touched, so the prod box and bastion are safe
- Lists the resource kinds swept: instances, security groups, key pairs, volumes, and the local VM
- States that a tag-based sweep verifies nothing tagged with the run id remains afterwards
- Mentions that runs whose TTL has not expired are skipped unless `--include-active` is passed, or that the instance TTL may already have terminated the instances

FAIL if:
- Proposes terminating instances or deleting security groups by name, by age, or account-wide without the tag filter
- Suggests any action that could touch the prod box or bastion
- Declares the account clean without a verification sweep
