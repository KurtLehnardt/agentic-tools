#!/usr/bin/env bash
# offline-test.sh: offline checks for the validate-install scripts. Needs no AWS
# account, no network, and no VM.
#
# Usage:
#   tests/offline-test.sh
#
# remote-exec.sh is exercised end to end through a fake `ssh` on PATH. The fake
# ignores the connection options and runs the remote command locally with
# /bin/sh, with HOME pointing at a throwaway directory and PATH limited to
# /bin:/usr/bin, so the step wrapper runs under the system bash. On macOS that is
# bash 3.2, the same shell a stock macOS VM has. The fake home mimics Ubuntu's
# dotfiles: ~/.profile sources ~/.bashrc, and ~/.bashrc returns early for
# non-interactive shells before it adds a tool directory to PATH, the way nvm,
# bun, and rustup lines sit at the end of a real .bashrc.
#
# extract-readme-steps.sh is run against a fixture README that covers heredocs,
# backslash continuations, console prompts, non-shell fences, and untagged
# output or tree blocks.
#
# teardown.sh --orphans is run in --dry-run mode against a fake aws CLI to check
# that a run is skipped while any of its attempts is still inside its TTL.
#
# Exit code: 0 when every check passes, 1 otherwise.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS="$HERE/../scripts"
WORK="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$WORK"' EXIT

PASS=0 ; FAIL=0
ok()   { PASS=$((PASS + 1)); printf 'ok   %s\n' "$1"; }
bad()  { FAIL=$((FAIL + 1)); printf 'FAIL %s\n' "$1"; [ -z "${2:-}" ] || printf '%s\n' "$2" | sed 's/^/     /'; }
check() {  # check NAME COMMAND...
  local name="$1"; shift
  if "$@"; then ok "$name"; else bad "$name"; fi
}

# --- remote-exec.sh -------------------------------------------------------------
RUN_ID="vi-20260101000000-abcd"
SCOPE="linux-a1"
export VALIDATE_INSTALL_STATE="$WORK/state"
RD="$VALIDATE_INSTALL_STATE/$RUN_ID"
FAKE_HOME="$WORK/home"
FAKE_BIN="$WORK/fakebin"
mkdir -p "$RD" "$FAKE_HOME/tooldir" "$FAKE_BIN"

cat >"$RD/$SCOPE.env" <<ENV
SCOPE=$SCOPE
TARGET=linux
DISTRO=ubuntu
TRANSPORT=ssh
INSTANCE_ID=i-offlinetest
PUBLIC_IP=127.0.0.1
SSH_USER=tester
KEY_FILE=/dev/null
REGION=local
ENV

# Ubuntu-style dotfiles.
cat >"$FAKE_HOME/.profile" <<'PROFILE'
if [ -n "$BASH_VERSION" ] && [ -f "$HOME/.bashrc" ]; then . "$HOME/.bashrc"; fi
PROFILE
cat >"$FAKE_HOME/.bashrc" <<'BASHRC'
case $- in *i*) ;; *) return ;; esac
export PATH="$HOME/tooldir:$PATH"
BASHRC
printf '#!/bin/sh\necho faketool-ok\n' >"$FAKE_HOME/tooldir/faketool"
chmod +x "$FAKE_HOME/tooldir/faketool"

# Fake ssh: the last argument is the remote command. Like sshd, start in HOME.
cat >"$FAKE_BIN/ssh" <<FAKESSH
#!/bin/bash
for last in "\$@"; do :; done
cd "$FAKE_HOME" || exit 255
exec env -i HOME="$FAKE_HOME" PATH=/bin:/usr/bin LANG=C /bin/sh -c "\$last"
FAKESSH
chmod +x "$FAKE_BIN/ssh"

step() {  # step N [remote-exec args...] <<< command ; prints output, sets STEP_RC
  local n="$1"; shift
  set +e
  STEP_OUT="$(PATH="$FAKE_BIN:$PATH" "$SCRIPTS/remote-exec.sh" --run-id "$RUN_ID" --scope "$SCOPE" \
    --step "$n" --timeout 60 "$@" 2>&1)"
  STEP_RC=$?
  set -e
}

# shellcheck disable=SC2016  # $BASH_VERSION expands in the child shell
REMOTE_BASH="$(env -i PATH=/bin:/usr/bin bash -c 'echo "$BASH_VERSION"')"
echo "remote bash under test: $REMOTE_BASH"

step 1 <<'S'
mkdir -p proj/sub && cd proj/sub && export FOO=bar && export TRICKY='a b "c" $d'
S
check "step 1 exits 0" test "$STEP_RC" = 0

step 2 <<'S'
echo "cwd=$PWD"; echo "foo=$FOO"; echo "tricky=$TRICKY"
S
check "step 2 exits 0" test "$STEP_RC" = 0
case "$STEP_OUT" in *"cwd=$FAKE_HOME/proj/sub"*) ok "cwd persists across steps" ;;
  *) bad "cwd persists across steps" "$STEP_OUT" ;; esac
case "$STEP_OUT" in *"foo=bar"*) ok "exported variable persists across steps" ;;
  *) bad "exported variable persists across steps" "$STEP_OUT" ;; esac
# shellcheck disable=SC2016  # literal $d is the expected value
case "$STEP_OUT" in *'tricky=a b "c" $d'*) ok "quoted value survives the session file" ;;
  *) bad "quoted value survives the session file" "$STEP_OUT" ;; esac

step 3 <<'S'
faketool
S
case "$STEP_RC:$STEP_OUT" in 0:*faketool-ok*) ok "PATH added in ~/.bashrc is visible (interactive login shell)" ;;
  *) bad "PATH added in ~/.bashrc is visible (interactive login shell)" "$STEP_OUT" ;; esac

LOG3="$RD/transcripts/$SCOPE/step-03.log"
if grep -Eq 'job control|terminal process group' "$LOG3"; then
  bad "job-control warnings are stripped from the transcript" "$(cat "$LOG3")"
else ok "job-control warnings are stripped from the transcript"; fi

step 4 <<'S'
mkdir -p "$HOME/newbin" && printf '#!/bin/sh\necho newtool-ok\n' > "$HOME/newbin/newtool" && chmod +x "$HOME/newbin/newtool" && export PATH="$HOME/newbin:$PATH"
S
step 5 <<'S'
newtool
S
case "$STEP_RC:$STEP_OUT" in 0:*newtool-ok*) ok "PATH exported by a step persists" ;;
  *) bad "PATH exported by a step persists" "$STEP_OUT" ;; esac

step 6 <<'S'
false
S
check "failing step returns its exit code" test "$STEP_RC" = 1

export VI_TEST_SECRET='s3cr3t-value-123'
step 7 --pass-env VI_TEST_SECRET <<'S'
echo "key is $VI_TEST_SECRET"; export STILL_HERE=yes
S
case "$STEP_OUT" in *"[REDACTED:VI_TEST_SECRET]"*) ok "forwarded secret is redacted in output" ;;
  *) bad "forwarded secret is redacted in output" "$STEP_OUT" ;; esac
if grep -rq 's3cr3t-value-123' "$RD/transcripts" "$FAKE_HOME/.vi-session"; then
  bad "secret never reaches the transcript or session file"
else ok "secret never reaches the transcript or session file"; fi
if grep -q 'STILL_HERE' "$FAKE_HOME/.vi-session" && grep -q 'FOO=' "$FAKE_HOME/.vi-session"; then
  ok "other exports are kept when a secret is filtered"
else bad "other exports are kept when a secret is filtered" "$(cat "$FAKE_HOME/.vi-session")"; fi

step 8 <<'S'
echo "cwd=$PWD foo=$FOO"
S
case "$STEP_OUT" in *"cwd=$FAKE_HOME/proj/sub foo=bar"*) ok "session still intact after a failing step" ;;
  *) bad "session still intact after a failing step" "$STEP_OUT" ;; esac

# --- extract-readme-steps.sh ----------------------------------------------------
README="$WORK/README.md"
cat >"$README" <<'MD'
# demo

## Install

```bash
git clone https://github.com/example/demo.git
cd demo
cat > .env <<'ENVFILE'
API_URL=http://localhost
# not a comment, part of the heredoc
ENVFILE
docker run \
  --rm \
  demo:latest
```

```console
$ npm install
added 12 packages
$ npm run build
```

```json
{ "name": "demo" }
```

```python
print("hello")
```

```
demo/
├── src/
│   └── main.ts
└── README.md
```

```
make install
```

```
Server listening on http://localhost:3000
```
MD
EXTRACT="$("$SCRIPTS/extract-readme-steps.sh" "$README")"
STEPS="$(printf '%s\n' "$EXTRACT" | awk -F'\t' '$1 == "STEP" { print $5 }')"
NSTEPS="$(printf '%s\n' "$EXTRACT" | awk -F'\t' '$1 == "STEP"' | wc -l | tr -d ' ')"

expect_step() {  # expect_step NAME SUBSTRING
  if printf '%s\n' "$STEPS" | grep -qF -- "$2"; then ok "$1"; else bad "$1" "$EXTRACT"; fi
}
reject_step() {
  if printf '%s\n' "$STEPS" | grep -qF -- "$2"; then bad "$1" "$EXTRACT"; else ok "$1"; fi
}
expect_step "heredoc kept as one step" "ENVFILE'\\nAPI_URL=http://localhost\\n# not a comment, part of the heredoc\\nENVFILE"
expect_step "heredoc body includes a hash line" '# not a comment, part of the heredoc'
expect_step "backslash continuation kept as one step" "docker run \\\\\\n  --rm \\\\\\n  demo:latest"
expect_step "console prompt stripped" 'npm install'
reject_step "console output line is not a step" 'added 12 packages'
reject_step "json fence skipped" '"name"'
reject_step "python fence skipped" 'print('
reject_step "untagged tree skipped" 'src/'
reject_step "untagged output skipped" 'Server listening'
expect_step "untagged command fence kept" 'make install'
DECODED="$(printf '%b' "$(printf '%s\n' "$EXTRACT" | awk -F'\t' '$1 == "STEP" && $2 == 4 { print $5 }')")"
WANT="$(printf 'docker run \\\n  --rm \\\n  demo:latest')"
if [ "$DECODED" = "$WANT" ]; then ok "printf %b decodes a step to the README text"
else bad "printf %b decodes a step to the README text" "$DECODED"; fi
if [ "$NSTEPS" = 7 ]; then ok "exactly 7 steps extracted"; else bad "exactly 7 steps extracted (got $NSTEPS)" "$EXTRACT"; fi

# --- teardown.sh --orphans: per-attempt expires-at ------------------------------
# A fake aws CLI (no network, no account) reports two runs. Run A has an expired
# first attempt and a second attempt still inside its TTL, so it must be skipped.
# Run B has only an expired attempt, so it must be swept. --dry-run deletes nothing.
RUN_A="vi-20260101000000-aaaa"
RUN_B="vi-20260101000000-bbbb"
PAST="2000-01-01T00:00:00Z"
FUTURE="2999-01-01T00:00:00Z"
AWS_BIN="$WORK/awsbin"
mkdir -p "$AWS_BIN"
cat >"$AWS_BIN/aws" <<FAKEAWS
#!/bin/bash
args="\$*"
case "\$args" in
  *"sts get-caller-identity"*) echo '{}' ;;
  *"describe-tags"*) printf '%s\t%s\n' "$RUN_A" "$RUN_B" ;;
  *"describe-security-groups"*"Values=$RUN_A"*"SecurityGroups[0]"*) echo "$PAST" ;;
  *"describe-security-groups"*"Values=$RUN_A"*"Tags["*) printf '%s\t%s\n' "$PAST" "$FUTURE" ;;
  *"describe-security-groups"*"Values=$RUN_B"*"Tags["*) echo "$PAST" ;;
  *) : ;;
esac
FAKEAWS
chmod +x "$AWS_BIN/aws"
set +e
TD_OUT="$(env -i HOME="$WORK/tdhome" PATH="$AWS_BIN:/usr/bin:/bin" VALIDATE_INSTALL_STATE="$WORK/tdstate" \
  "$SCRIPTS/teardown.sh" --orphans --region us-test-1 --dry-run 2>&1)"
set -e
case "$TD_OUT" in *"skipping $RUN_A"*) ok "orphan sweep skips a run whose latest attempt is still active" ;;
  *) bad "orphan sweep skips a run whose latest attempt is still active" "$TD_OUT" ;; esac
case "$TD_OUT" in *"sweeping run $RUN_B"*) ok "orphan sweep includes a fully expired run" ;;
  *) bad "orphan sweep includes a fully expired run" "$TD_OUT" ;; esac

echo "passed $PASS, failed $FAIL"
[ "$FAIL" = 0 ]
