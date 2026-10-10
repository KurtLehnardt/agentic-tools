---
type: llm
weight: 1
---

PASS if:
- Acknowledges that sandbox does NOT stop the injection, only bounds blast radius
- Includes the complete srt policy JSON in the reply, with `filesystem.allowRead` for the legitimate codebase (read allowed by default)
- Describes `filesystem.allowWrite` with ONLY minimum paths the agent's task requires (narrow whitelist, not broad ~/)
- Recommends `filesystem.denyRead` includes `"/.ssh"` and `"/.aws"`
- States `network.allowedDomains=[]` (full egress deny, no bypass)
- Explicitly lists what's unreachable: .env files, AWS credentials, SSH keys, cron/hooks, ~/.bash_profile, package.json
- Frames security defense as OS-level containment

FAIL if:
- Suggests trying to fix the agent's behavior via prompt
- Claims sandbox prevents injection
- Does not mention deny-by-default network policy
- Does not emphasize blast radius bounding as the defense model
- Recommends broad write whitelist (e.g., ~/ or /)
