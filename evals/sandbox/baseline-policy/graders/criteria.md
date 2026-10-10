---
type: llm
weight: 1
---

PASS if:
- Includes the complete ~/.srt-settings.json policy JSON in the reply, with `filesystem` and `network` fields
- States `filesystem.allowRead=[]` (read allowed by default, no allowRead list needed)
- States `filesystem.allowWrite` includes `"src/"`, `"test/"`, and optionally `"/tmp"`
- States `filesystem.denyWrite` includes at least `".git/hooks"` and `"package.json"`
- States `network.allowedDomains=[]` (fully denied, no bypass)
- Mentions `srt` CLI invocation to run agent inside sandbox
- Explains that policy determines blast radius when injection occurs

FAIL if:
- Output includes `.env` in the write whitelist
- Output includes `.ssh` in the write whitelist
- Output includes `.aws` in the write whitelist
- Output includes shell rc files (`.bash_profile`, `.zshrc`) in the write whitelist
- Output includes cron in the write whitelist
- Does not mention deny-by-default egress policy
- Does not explain the relationship between policy and blast radius
