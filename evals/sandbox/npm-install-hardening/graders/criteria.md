---
type: llm
weight: 1
---

PASS if:
- Includes the complete srt policy JSON in the reply
- Write allowlist MUST include `"node_modules/"` and `".next/cache"`
- Write denylist MUST include all of: `".npmrc"`, `".git/hooks"`, `"~/.bash_profile"`, `"~/.zshrc"`, `"/etc/cron.d"`, `"~/.husky"`, `"package.json"`
- Egress allowlist MUST include `"registry.npmjs.org:443"` and optionally @scope registries
- Egress list does NOT include other domains
- Explains that violation telemetry flags writes to denyWrite paths
- Notes denyWrite prevents both npm-internal hooks and agent-direct persistence attempts

FAIL if:
- Grants broad npm network access
- Allows `package.json` writes
- Does not include `node_modules/` in write allowlist
- Does not include `.next/cache` in write allowlist
- Missing any required denyWrite entry: `.npmrc`, `.git/hooks`, `~/.bash_profile`, `~/.zshrc`, `/etc/cron.d`, `~/.husky`, `package.json`
- Includes unnecessary domains in egress allowlist
