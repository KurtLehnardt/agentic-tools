# Failure triage for /validate-install

Classify every failing step before changing anything. Read the step transcript in
`<state>/<run-id>/transcripts/<scope>/step-NN.log` and pick exactly one class.

| Class | Signal | Fix location |
|-------|--------|--------------|
| README bug | The command works once an unstated prerequisite, env var, or ordering is added. Examples: `npm: command not found` on a clean box, a step that needs `cd repo` first, a placeholder the README never explains. | The README. Add the prerequisite, the missing step, or the explanation. |
| Code bug | The README is followed exactly and correctly, and the project's own script or binary fails. Examples: an installer that hardcodes `/opt/homebrew`, a postinstall that assumes macOS `sed -i ''`, a missing file in the package. | The installer or source code, with a test when the repo has a suite. |
| Environment | The failure comes from the validation setup and a real user would not hit it. Examples: AMI mirror outage, rate-limited download, SSM agent not ready, disk full because `--volume-gb` was too small. | Nothing in the repo. Adjust the run (bigger volume, retry, other region) and record it. |

Rules:
- A failure is an environment problem only when you can name the setup cause. When unsure,
  treat it as a README bug: a stranger hitting it would also be stuck.
- A real user on that OS would hit a missing system package too. That is a README bug, not an
  environment problem, even though the fix is "install X first".
- Fixes go on a branch named `fix/validate-install-<run-id>` in the target repo. Never commit
  to the default branch. When the repo is not writable, write the proposed patch into the report.
- After any fix, provision a brand-new instance with the next `--attempt` number. Never re-run on
  the instance that already failed, because its state is no longer fresh.
- Stop after attempt 3 for a target and report it as FAIL with the last failing step.

## Interactive prompts

`remote-exec.sh` runs every step with stdin from `/dev/null`. A step that waits for input fails
fast. When the README expects the user to answer a prompt, record it as a README note, then re-run
the step with the documented answer piped in (for example `yes | ./install.sh`) and state that
substitution in the report.

## Local LLM paths

When the README offers a local-model path, pick models that fit the target's RAM, leaving about
2 GiB for the OS and the app. Approximate sizes for 4-bit quantized weights: 3B models need about
2-3 GiB, 7B-8B about 5-6 GiB, 13B-14B about 9-10 GiB. On a `t3.large` (8 GiB) only 3B-class
models fit; use `t3.xlarge` (16 GiB) or `r7i.xlarge` (32 GiB) for 7B-14B. CPU-only inference is
slow, so verify with a single short prompt and a generous timeout rather than a benchmark.
