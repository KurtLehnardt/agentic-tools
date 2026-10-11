#!/usr/bin/env bash
# lib.sh: shared helpers for the validate-install scripts. Source it; do not execute it.
#
# Credentials: every script relies on the AWS CLI's normal credential chain
# (AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY exported from the shell profile, or
# AWS_PROFILE). No script reads, prints, or logs a credential value, and none
# of them enable `set -x`.

# shellcheck disable=SC2034  # variables are consumed by the scripts that source this file
TAG_KEY="agentic-tools:validate-install"
SCOPE_TAG_KEY="agentic-tools:validate-install-scope"
EXPIRES_TAG_KEY="agentic-tools:expires-at"
IAM_PATH="/agentic-tools/validate-install/"
RUN_ID_RE='^vi-[0-9]{14}-[0-9a-f]{4}$'
STATE_ROOT="${VALIDATE_INSTALL_STATE:-$HOME/.cache/agentic-tools/validate-install}"
export AWS_PAGER=""

log() { printf '[validate-install] %s\n' "$*" >&2; }

die() {
  log "ERROR: $1"
  exit "${2:-1}"
}

require_cmd() {
  local c
  for c in "$@"; do
    command -v "$c" >/dev/null 2>&1 || die "missing required command: $c" 2
  done
}

valid_run_id() {
  [[ "$1" =~ $RUN_ID_RE ]] || die "invalid run id '$1' (expected vi-YYYYMMDDHHMMSS-xxxx)" 2
}

run_dir() { printf '%s/%s' "$STATE_ROOT" "$1"; }

now_utc() { date -u +%Y-%m-%dT%H:%M:%SZ; }

# utc_plus_hours N -> ISO timestamp N hours from now (BSD and GNU date).
utc_plus_hours() {
  date -u -v+"$1"H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null ||
    date -u -d "+$1 hours" +%Y-%m-%dT%H:%M:%SZ
}

# utc_plus_minutes N -> ISO timestamp N minutes from now (BSD and GNU date).
utc_plus_minutes() {
  date -u -v+"$1"M +%Y-%m-%dT%H:%M:%SZ 2>/dev/null ||
    date -u -d "+$1 minutes" +%Y-%m-%dT%H:%M:%SZ
}

# Minutes added to the TTL when a resource's expires-at tag is computed. The
# instance only starts its shutdown timer once it has booted, so the tag must
# cover boot time; otherwise `teardown.sh --orphans` could treat a live attempt
# as expired.
EXPIRES_SLACK_MINUTES=20

# resolve_region [explicit] -> region from flag, env, or CLI profile.
resolve_region() {
  local r="${1:-}"
  [ -n "$r" ] || r="${AWS_REGION:-${AWS_DEFAULT_REGION:-}}"
  [ -n "$r" ] || r="$(aws configure get region 2>/dev/null || true)"
  [ -n "$r" ] || die "no AWS region: pass --region, export AWS_REGION, or set one in the CLI profile" 2
  printf '%s' "$r"
}

# load_run_env RUN_ID: source the run.env written by preflight.sh.
load_run_env() {
  local f
  f="$(run_dir "$1")/run.env"
  [ -f "$f" ] || die "missing $f (run preflight.sh first)" 2
  # shellcheck disable=SC1090
  . "$f"
}
