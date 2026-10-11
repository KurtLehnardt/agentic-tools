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
# targets the step runs under `bash -il`, an interactive login shell, so the
# remote shell reads ~/.bash_profile or ~/.profile and also ~/.bashrc. Stock
# .bashrc files return early when the shell is not interactive, and that early
# return would drop the PATH lines that installers such as nvm, bun, and rustup
# append there. Stdin is /dev/null, so an interactive prompt fails fast instead
# of hanging. Because there is no terminal, bash prints "cannot set terminal
# process group" and "no job control in this shell" at startup; those two lines
# are removed from the transcript. The cwd and exports are saved to
# ~/.vi-session after each step and restored with eval, which works on bash 3.2
# (stock macOS), where sourcing a process substitution silently does nothing.
# The script is staged in a mktemp file (mode 600) on the target and removed
# after the step.
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
  # shellcheck disable=SC2016  # expands on the remote side
  REMOTE_RUNNER='f=$(mktemp); cat >"$f"; bash -il "$f" </dev/null; rc=$?; rm -f "$f"; exit $rc'
  {
    for v in ${pass_vars[@]+"${pass_vars[@]}"}; do
      printf "export %s='%s'\n" "$v" "$(printf '%s' "${!v}" | sed "s/'/'\\\\''/g")"
    done
    printf 'VI_SECRETS=%q\n' "${PASS_ENV//,/ }"
    cat <<'PRE'
if [ -f ~/.vi-session ]; then
  vi_path_saved="$(sed -n 's/^VI_PATH=//p' ~/.vi-session)"
  eval "$(grep -v '^VI_PATH=' ~/.vi-session)" 2>/dev/null
  cd "${VI_CWD:-$HOME}" 2>/dev/null || cd "$HOME"
  [ -n "$vi_path_saved" ] && PATH="$PATH:$vi_path_saved"
fi
PRE
    printf '%s\n' "$CMD"
    cat <<'POST'
vi_rc=$?
{
  printf 'VI_CWD=%q\n' "$PWD"
  printf 'VI_PATH=%s\n' "$PATH"
  vi_exports="$(export -p | grep -Ev '^declare -x (PATH|PWD|OLDPWD|SHLVL|_|VI_[A-Z_]+)=')"
  for vi_s in $VI_SECRETS; do
    vi_exports="$(printf '%s\n' "$vi_exports" | grep -v "^declare -x $vi_s=")"
  done
  printf '%s\n' "$vi_exports"
} > ~/.vi-session
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
