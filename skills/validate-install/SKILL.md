---
name: validate-install
description: "Prove a repo's README install instructions work on fresh Linux, Windows, and macOS machines exactly as a stranger would run them, fix what breaks, and always tear everything down. Trigger: validate the install, test the installer, fresh machine test, does the README install work, test on linux VM, test on windows VM, test on mac VM, is it ready for someone to clone."
user-invocable: true
---

# /validate-install: Fresh-Machine Install Validation

You are an **orchestrator** answering one question: can a stranger clone this repo, follow the README, and end up with a working install? You answer it by running the README literally on brand-new machines, fixing what breaks, and leaving nothing running afterwards.

## Usage

```
/validate-install [--targets linux,windows,mac] [--distro ubuntu|arch|amazon]
                  [--instance-type t3.large] [--region <r>] [--readme <path>]
                  [--ttl-hours 2] [--keep] [--yes]
```

- `--targets` defaults to `linux`. `linux` and `windows` run on EC2. `mac` runs as a local VM through `tart`, or through UTM's `utmctl` when tart is missing.
- `--distro` applies to Linux and defaults to `ubuntu` (24.04). `amazon` is Amazon Linux 2023.
- `--readme` defaults to `README.md` at the repo root.
- `--keep` leaves resources running after the report and prints the exact cleanup command.
- `--yes` skips the single cost confirmation.

All helpers live in `scripts/` next to this file. Every script uses `set -euo pipefail` and documents its usage in its header comment.

## Credentials

AWS credentials come from the environment the user already has: `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` exported in the shell profile (for example `~/.zshrc`), or `AWS_PROFILE` pointing at a CLI profile. The scripts rely on the AWS CLI's normal credential chain.

1. Never ask the user to paste keys into chat. If they offer, tell them to export the keys in their shell profile or run `aws configure --profile <name>` in their own terminal, then restart the session.
2. Never echo, log, or write a credential value. Never run `env`, `printenv`, or `set -x` in a session that has AWS keys loaded.
3. When the README needs the user's own API key (for example an LLM provider key), forward it from the local environment with `remote-exec.sh --pass-env VAR`. The value travels over the SSH stream, is never written to the remote session file, and is redacted from transcripts. On Windows, prefer the README's local-model path, because SSM stores command text in AWS history.
4. Recommend a dedicated least-privilege IAM user. The policy is in `references/iam-policy.md`.

## Phase 1: Preflight

```bash
scripts/preflight.sh --targets linux,windows --instance-type t3.large --region us-east-1 --ttl-hours 2
```

The script verifies `aws sts get-caller-identity`, resolves the region, reads the caller's public IP, looks up the instance type's vCPU and RAM, reads the standard on-demand vCPU quota (`L-1216C47A`), counts already-tagged instances, and prints a cost estimate for one attempt and for the worst case of three attempts. It creates nothing in AWS. It writes `run.env` under `~/.cache/agentic-tools/validate-install/<run-id>/` and prints `RUN_ID=vi-YYYYMMDDHHMMSS-xxxx`.

Show the user the account, region, targets, instance type, TTL, tag, and cost estimate. **Ask for one confirmation before the first launch** unless `--yes` was passed. Do not ask again for re-provisioning within the same run.

Every resource created in this run carries the tag `agentic-tools:validate-install=<run-id>`, plus a scope tag and an `agentic-tools:expires-at` timestamp. Every EC2 instance gets a hard TTL: user data schedules a shutdown at the TTL and the instance's shutdown behavior is `terminate`, so it deletes itself even if this session dies.

## Phase 2: Extract the README Steps

```bash
scripts/extract-readme-steps.sh README.md
```

The script prints each command from shell-tagged code fences in order, with its section heading, and flags heuristics: `UNDOCUMENTED_ENV`, `UNSTATED_PREREQ`, `INTERACTIVE`, and `PLACEHOLDER`. Read the README yourself as well and confirm or dismiss each flag. Build a per-target step list that keeps the README's wording exactly. Where the README branches by OS, take the branch for that target. Where it offers a choice (an API key or a local LLM), validate the path a new user is most likely to take and note the others.

Report every assumption the README never states before running anything, for example a required tool version, a system package, an env var the code reads, or a step that only works from inside the cloned directory.

## Phase 3: Provision Fresh Machines

Run targets in parallel when there is more than one.

```bash
scripts/provision-ec2.sh --run-id "$RUN_ID" --target linux --distro ubuntu --attempt 1
scripts/provision-ec2.sh --run-id "$RUN_ID" --target windows --attempt 1
scripts/mac-vm.sh create --run-id "$RUN_ID" --attempt 1 --memory-gb 8
```

- Linux gets an ephemeral ed25519 key pair and a security group that allows only tcp/22 from the caller's `/32`.
- Windows gets a security group with no ingress at all and is reached through SSM, using a run-scoped IAM role and instance profile under `/agentic-tools/validate-install/`.
- Root volumes are gp3 with `DeleteOnTermination=true`. Instances require IMDSv2.
- The mac VM is cloned from a stock image with no Homebrew, so missing prerequisites show up. Its name `<run-id>-mac-a<N>` acts as its tag.

If provisioning fails or is interrupted, the script's own trap tears down everything it created for that scope.

## Phase 4: Run the Steps Like a Stranger

Run each step through `remote-exec.sh`, one call per step, passing the command text verbatim on stdin:

```bash
scripts/remote-exec.sh --run-id "$RUN_ID" --scope linux-a1 --step 3 <<'STEP'
git clone https://github.com/owner/repo && cd repo
STEP
```

The working directory and exported variables persist between steps, as they would in one terminal. Every step writes a transcript to `transcripts/<scope>/step-NN.log` containing the command, output, exit code, and duration. Stop a target at its first failing step. Do not improvise extra commands to get past a failure, because that hides the bug a stranger would hit. The only allowed additions are the README's own documented answers to interactive prompts, and the report must name each one.

After the last step, run the README's own "verify" or "usage" command. If the README has none, run the smallest real use of the tool and record that the README lacks a verification step.

## Phase 5: Triage, Fix, Re-Run

Classify each failure as a README bug, a code bug, or an environment problem using `references/failure-triage.md`. Then:

1. For README and code bugs, fix them on a branch `fix/validate-install-<run-id>` in the repo when it is writable. Otherwise write the proposed patch into the report.
2. Provision a brand-new machine with the next `--attempt` number and run every step again from step 1. Never reuse the machine that failed.
3. Tear down the failed attempt's scope right away: `scripts/teardown.sh --run-id "$RUN_ID" --scope linux-a1`.
4. Stop after attempt 3 for any target and report it as FAIL.

Environment problems get a retry with an adjusted run (bigger volume, another region) and are recorded, but they never change the repo.

## Phase 6: Local LLM Path (Optional)

When the README offers a local-model path such as ollama, validate it on each target with models that fit the instance RAM. Sizing guidance is in `references/failure-triage.md`. A `t3.large` (8 GiB) fits only 3B-class models, so suggest `--instance-type t3.xlarge` or larger when the README's recommended model is 7B or above, and include the price difference in the estimate.

## Phase 7: Report

```
Install validation: <repo> @ <commit>   run <run-id>   region us-east-1

| Target          | Result | Attempts | Failing step            | Class      |
|-----------------|--------|----------|-------------------------|------------|
| linux (ubuntu)  | PASS   | 2        | -                       | -          |
| windows 2022    | FAIL   | 3        | 4: npm run build        | code bug   |
| mac (sequoia)   | PASS   | 1        | -                       | -          |

README assumptions found: Node 20 not listed as a prerequisite; OPENAI_API_KEY never explained.
Fixes: branch fix/validate-install-<run-id>, 2 commits (README prereqs, installer path quoting).
Local LLM: llama3.2:3b answered on linux and mac.
Cost: about $0.41 (3 instance-hours of t3.large, 1 of Windows t3.large).
Transcripts: ~/.cache/agentic-tools/validate-install/<run-id>/transcripts/
Teardown: VERIFIED, 0 resources tagged agentic-tools:validate-install=<run-id> remain.
```

Compute cost from actual instance launch and termination times multiplied by the hourly price used in preflight.

## Teardown Is Mandatory

Treat Phases 3 through 7 as a `try` block and teardown as its `finally`. Run it on success, on failure, on a blocked step, when the user interrupts, and when you decide to stop early:

```bash
scripts/teardown.sh --run-id "$RUN_ID"
```

It terminates instances and waits for them, then deletes security groups, key pairs, leftover volumes, the IAM instance profile and role, the local VM, and the local private keys. It then re-queries by tag and prints `VERIFIED: 0 resources ... remain`, or lists what remains and exits 1. It is idempotent, so run it again until it verifies. It touches only resources whose run tag equals this run id. The final report must quote the verification line.

With `--keep`, skip teardown, say that the EC2 TTL still terminates the instances at `expires-at`, and print the exact command: `scripts/teardown.sh --run-id <run-id> --region <region>`.

### Orphans from crashed runs

```bash
scripts/teardown.sh --orphans --all-regions --dry-run   # list what would be deleted
scripts/teardown.sh --orphans --all-regions             # delete it, then verify
```

Orphan mode finds every run id carrying the tag key. It skips runs whose `expires-at` is still in the future, because another session may be using them, unless `--include-active` is passed.

## Safety Rules

1. One cost confirmation before the first launch, unless `--yes`.
2. Never create, modify, or delete a resource that lacks this run's tag. Never run a broad cleanup without the tag filter.
3. Never accept credentials in chat, and never print them.
4. Every EC2 instance has a hard TTL and terminates itself.
5. Teardown always runs, and the report always states whether it verified clean.
6. Never push fixes to the default branch.
