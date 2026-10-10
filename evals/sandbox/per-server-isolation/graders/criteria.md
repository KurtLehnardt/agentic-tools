---
type: llm
weight: 1
---

PASS if:
- Includes the complete per-server srt policy JSON in the reply
- Describes wrapping each MCP server command with `srt` (e.g., `"command": "srt"`, `"args": [...]`)
- Explains each server gets its own srt policy (dedicated settings file per server or per-invocation customConfig)
- Filesystem server: `filesystem.allowWrite=["."]`, `network.allowedDomains=[]`
- Gmail server: `filesystem.allowWrite=[]`, `network.allowedDomains=["gmail.googleapis.com:443"]`
- GitHub server: `filesystem.allowWrite=[]`, `network.allowedDomains=["api.github.com:443"]`
- AWS-cli server: `filesystem.allowRead` (config read only), `network.allowedDomains=["aws-api-domain:443"]` (scoped)
- Explains that one compromised server is contained independently

FAIL if:
- Allows cross-server reach
- Recommends broad network access
- Does not wrap servers individually with srt
- Does not propose dedicated policies per server
- GitHub server entry does not list `api.github.com:443` exactly
