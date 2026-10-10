---
name: capture-api-key-revocation-window-90s
description: Capture security prod incident (API key revocation window), confirm deterministic reproducibility, name level, tag with both 'prod-incident' and 'security', add to gate for /build and /verdict.
tags: [capture]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

/capture — We had a production incident yesterday. Admin API keys were still authenticating requests for 90+ seconds after revocation. This is a security issue. I've confirmed the exact sequence: admin revokes key at T=0, key returns 'revoked' from /keys endpoint at T=1, but API requests using that key still validate until T=90. Happens consistently.
