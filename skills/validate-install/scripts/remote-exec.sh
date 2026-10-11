#!/usr/bin/env bash
# remote-exec.sh: run one README step on a provisioned target, the way a new
# user would type it, and capture a per-step transcript.
#
# Usage:
#   remote-exec.sh --run-id ID --scope linux-a1 --step N [--timeout 1800]
#                  [--pass-env VAR1,VAR2] < step.txt
#
# The step's command text is read verbatim from stdin.
# Session continuity: a stranger types every step into one terminal, so the
# working directory and exported variables carry over between steps. On ssh
# targets each step runs in an interactive login shell of the kind a new user
# gets when they open a terminal: `bash -il` on Linux, and `zsh -il` on macOS,
# whose default login shell is zsh. Login bash reads ~/.bash_profile or
# ~/.profile and also ~/.bashrc; stock .bashrc files return early when the
# shell is not interactive, and that early return would drop the PATH lines
# that installers such as nvm, bun, and rustup append there. Login zsh reads
# ~/.zprofile, where Homebrew writes `brew shellenv`, and ~/.zshrc, where bun
# and nvm write their lines. Stdin is /dev/null, so an interactive prompt
# fails fast instead of hanging. Because there is no terminal, bash prints
# "cannot set terminal process group" and "no job control in this shell" at
# startup; those two lines are removed from the transcript.
# After each step the cwd, PATH, and exported variables are saved to
# ~/.vi-session as single-quoted `export NAME='value'` lines, which bash
# (including bash 3.2 on stock macOS) and zsh both read with `.`. They are
# listed by awk from its environment, so the format does not depend on the
# shell's own `export -p` output. On restore the saved PATH comes first, so a
# directory that an earlier step prepended keeps its precedence; directories
# that the login files add and that are not already saved are appended.
# The script is staged in a mktemp file (mode 600) on the target. The script
# deletes that file as its first action, because the file can hold --pass-env
# values; the runner also removes it on exit as a backup.
# On Windows (SSM, PowerShell) the cwd is saved and PATH is reloaded from the
# registry before each step, which matches opening a new terminal.
#
# --pass-env forwards named variables from this machine (for example a user's
# own API key) over the ssh stdin stream. Their values never appear in argv,
# are never written to the remote session file, and are replaced with
# [REDACTED:VAR] in the transcript. --pass-env is refused for Windows, because
# SSM stores command text in the AWS command history.
#
# Transcript: <state>/<run-id>/transcripts/<scope>/step-NN.log
# Exit code: the step's own exit code (124 on timeout).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR source=lib.sh
. "$SCRIPT_DIR/lib.sh"

RUN_ID="" ; SCOPE="" ; STEP="" ; TIMEOUT=1800 ; PASS_ENV=""
while [ $# -gt 0 ]; do
  case "$1" in
    --run-id) RUN_ID="$2"; shift 2 ;;
    --scope) SCOPE="$2"; shift 2 ;;
    --step) STEP="$2"; shift 2 ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    --pass-env) PASS_ENV="$2"; shift 2 ;;
    *) die "unknown argument: $1" 2 ;;
  esac
done
valid_run_id "$RUN_ID"
[[ "$STEP" =~ ^[0-9]+$ ]] || die "--step must be a number" 2
RD="$(run_dir "$RUN_ID")"
[ -f "$RD/$SCOPE.env" ] || die "unknown scope $SCOPE (provision it first)" 2
# shellcheck disable=SC1090
. "$RD/$SCOPE.env"

CMD="$(cat)"
[ -n "$CMD" ] || die "empty step on stdin" 2
TDIR="$RD/transcripts/$SCOPE"
mkdir -p "$TDIR"
LOG="$TDIR/$(printf 'step-%02d.log' "$STEP")"
RAW="$(mktemp)"
trap 'rm -f "$RAW" "$RAW.f"' EXIT

pass_vars=()
if [ -n "$PASS_ENV" ]; then
  IFS=',' read -r -a pass_vars <<<"$PASS_ENV"
  for v in "${pass_vars[@]}"; do
    [[ "$v" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || die "bad variable name in --pass-env: $v" 2
    [ -n "${!v:-}" ] || die "--pass-env $v is not set in this environment" 2
  done
fi

# macOS ships no `timeout`; coreutils provides `gtimeout`.
TIMEOUT_CMD=()
if command -v timeout >/dev/null 2>&1; then TIMEOUT_CMD=(timeout "$TIMEOUT")
elif command -v gtimeout >/dev/null 2>&1; then TIMEOUT_CMD=(gtimeout "$TIMEOUT")
else log "no timeout/gtimeout found; step $STEP runs without a local timeout"; fi

START="$(date +%s)"
set +e
if [ "$TRANSPORT" = ssh ]; then
  # The login shell a new user gets on the target: zsh on macOS, bash elsewhere.
  RUNNER_SHELL=bash
  [ "${TARGET:-}" = mac ] && RUNNER_SHELL=zsh
  # The script file is passed as $1 so that the script can delete it first.
  # shellcheck disable=SC2016  # expands on the remote side
  REMOTE_RUNNER='f=$(mktemp) || exit 255; trap '"'"'rm -f "$f"'"'"' EXIT HUP INT TERM; cat >"$f"; '"$RUNNER_SHELL"' -il "$f" "$f" </dev/null; rc=$?; rm -f "$f"; exit $rc'
  {
    # The harness lines below contain no comments, because they run inside an
    # interactive shell.
    cat <<'SELF'
vi_self="$1"; shift; rm -f "$vi_self"; unset vi_self
SELF
    for v in ${pass_vars[@]+"${pass_vars[@]}"}; do
      printf "export %s='%s'\n" "$v" "$(printf '%s' "${!v}" | sed "s/'/'\\\\''/g")"
    done
    printf "VI_SECRETS='%s'\n" "${PASS_ENV//,/ }"
    cat <<'PRE'
if [ -f ~/.vi-session ]; then
  VI_PATH=""
  . ~/.vi-session
  cd "${VI_CWD:-$HOME}" 2>/dev/null || cd "$HOME"
  if [ -n "$VI_PATH" ]; then
    PATH="$(printf '%s:%s\n' "$VI_PATH" "$PATH" | tr ':' '\n' | awk 'NF && !seen[$0]++' | paste -s -d : -)"
    export PATH
  fi
fi
PRE
    printf '%s\n' "$CMD"
    cat <<'POST'
vi_rc=$?
VI_CWD="$PWD" VI_PATH="$PATH" VI_SECRETS="$VI_SECRETS" awk '
function q(s,   o, i) {
  o = ""
  while ((i = index(s, "\047")) > 0) { o = o substr(s, 1, i - 1) "\047\\\047\047"; s = substr(s, i + 1) }
  return "\047" o s "\047"
}
BEGIN {
  n = split(ENVIRON["VI_SECRETS"], sec, " "); for (i = 1; i <= n; i++) skip[sec[i]] = 1
  n = split("PATH PWD OLDPWD SHLVL _ SHELLOPTS BASHOPTS", sk, " "); for (i = 1; i <= n; i++) skip[sk[i]] = 1
  printf "VI_CWD=%s\nVI_PATH=%s\n", q(ENVIRON["VI_CWD"]), q(ENVIRON["VI_PATH"])
  for (k in ENVIRON) {
    if (k !~ /^[A-Za-z_][A-Za-z0-9_]*$/ || k ~ /^VI_/ || (k in skip)) continue
    printf "export %s=%s\n", k, q(ENVIRON[k])
  }
}' > ~/.vi-session
exit $vi_rc
POST
  } | ${TIMEOUT_CMD[@]+"${TIMEOUT_CMD[@]}"} ssh -i "$KEY_FILE" -o BatchMode=yes -o ServerAliveInterval=30 \
      -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile="$RD/known_hosts" \
      "$SSH_USER@$PUBLIC_IP" \
      "$REMOTE_RUNNER" >"$RAW" 2>&1
  RC=$?
else
  [ -z "$PASS_ENV" ] || die "--pass-env is not supported on Windows/SSM targets" 2
  require_cmd python3
  # shellcheck disable=SC2016  # PowerShell text, not bash
  PS_PRE='$ErrorActionPreference = "Continue"
New-Item -ItemType Directory -Force -Path C:\vi | Out-Null
$env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")
if (Test-Path C:\vi\cwd.txt) { Set-Location (Get-Content C:\vi\cwd.txt) } else { Set-Location $env:PUBLIC }'
  # shellcheck disable=SC2016  # PowerShell text, not bash
  PS_POST='$viRc = if ($LASTEXITCODE) { $LASTEXITCODE } elseif ($?) { 0 } else { 1 }
(Get-Location).Path | Set-Content C:\vi\cwd.txt
exit $viRc'
  PS_SCRIPT="$(printf '%s\n%s\n%s\n' "$PS_PRE" "$CMD" "$PS_POST")"
  PARAMS="$(printf '%s' "$PS_SCRIPT" | python3 -c 'import json,sys; t=sys.argv[1]; print(json.dumps({"commands": sys.stdin.read().splitlines(), "executionTimeout": [t]}))' "$TIMEOUT")"
  CID="$(aws --region "$REGION" ssm send-command --instance-ids "$INSTANCE_ID" \
    --document-name AWS-RunPowerShellScript --parameters "$PARAMS" \
    --comment "validate-install $RUN_ID $SCOPE step $STEP" --query 'Command.CommandId' --output text)"
  STATUS=Pending
  while :; do
    sleep 5
    STATUS="$(aws --region "$REGION" ssm get-command-invocation --command-id "$CID" \
      --instance-id "$INSTANCE_ID" --query Status --output text 2>/dev/null || echo Pending)"
    case "$STATUS" in Pending|InProgress|Delayed) continue ;; *) break ;; esac
  done
  aws --region "$REGION" ssm get-command-invocation --command-id "$CID" --instance-id "$INSTANCE_ID" \
    --query '[StandardOutputContent,StandardErrorContent]' --output text >"$RAW" 2>&1
  RC="$(aws --region "$REGION" ssm get-command-invocation --command-id "$CID" \
    --instance-id "$INSTANCE_ID" --query ResponseCode --output text)"
  [ "$STATUS" = TimedOut ] && RC=124
  echo "(SSM output is truncated by AWS at 24000 characters)" >>"$RAW"
fi
set -e
END="$(date +%s)"

# Redact forwarded secret values from the transcript (literal match, no regex).
redact() {
  local f="$1" v val
  for v in ${pass_vars[@]+"${pass_vars[@]}"}; do
    val="${!v}"
    VAL="$val" NAME="$v" awk '{
      s = $0; out = ""; n = length(ENVIRON["VAL"])
      while ((i = index(s, ENVIRON["VAL"])) > 0) { out = out substr(s, 1, i - 1) "[REDACTED:" ENVIRON["NAME"] "]"; s = substr(s, i + n) }
      print out s }' "$f" >"$f.tmp" && mv "$f.tmp" "$f"
  done
}
redact "$RAW"

# `bash -il` without a terminal prints these two job-control warnings at startup.
# They come from the harness, not the README step, so drop them.
grep -Ev '^(bash: )?(cannot set terminal process group \([-0-9]+\): Inappropriate ioctl for device|no job control in this shell)$' \
  "$RAW" >"$RAW.f" || true
mv "$RAW.f" "$RAW"

{
  echo "# step:     $STEP"
  echo "# scope:    $SCOPE ($TARGET/$DISTRO, $INSTANCE_ID)"
  echo "# started:  $(date -u -r "$START" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$START" +%Y-%m-%dT%H:%M:%SZ)"
  echo "# command:"
  printf '%s\n' "$CMD" | sed 's/^/#   /'
  echo "# ---- output ----"
  cat "$RAW"
  echo "# ---- exit $RC after $((END - START))s ----"
} >"$LOG"

tail -n 40 "$LOG"
exit "$RC"
