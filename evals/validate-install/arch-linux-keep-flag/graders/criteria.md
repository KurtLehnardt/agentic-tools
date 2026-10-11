---
type: llm
weight: 1
---

PASS if:
- States that AWS credentials are read from the environment or the AWS CLI profile and does not ask the user to paste keys
- Names a preflight that includes `aws sts get-caller-identity` and the region
- Shows or promises a cost estimate and asks for one confirmation before the first launch
- Names the tag `agentic-tools:validate-install=<run-id>` (or the tag key `agentic-tools:validate-install`) as applied to every resource
- States that the instance has a hard TTL after which it terminates itself
- Selects Arch Linux as the distro for the Linux target
- Because of the keep request, states that teardown is skipped and prints an exact cleanup command that includes `teardown.sh` and the run id

FAIL if:
- Claims an instance was launched, a step ran, or the install passed, since nothing could execute in this session
- Asks the user to paste AWS access keys into the chat
- Omits the cleanup command for the kept resources
- Uses Ubuntu or Amazon Linux instead of Arch for the Linux target without saying why
