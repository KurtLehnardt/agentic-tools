---
type: llm
weight: 1
---

PASS if:
- Describes `srt --debug <cmd>` for verbose denial logging
- Explains programmatic monitoring via `SandboxViolationStore` with `getViolationsForCommand(key)` and `annotateStderrWithSandboxFailures(key, stderr)`
- Notes macOS has strong real-time violation telemetry via system sandbox violation log
- Notes Linux telemetry is future work (suggests strace as workaround)
- Identifies egress-denied events as primary injection signal
- Explains how to feed violations to `/observe` skill as anomaly signals
- Mentions `/verdict` gate can require 'zero unexplained egress-denied violations'

FAIL if:
- Claims violations stop the attack
- Does not mention denied egress as injection indicator
- Does not explain the programmatic SandboxViolationStore API
- Does not differentiate between macOS and Linux telemetry capabilities
- Does not explain how to feed violations to /observe
