#!/usr/bin/env bash
# Test suite for the agentic-tools hooks.
#
# Usage: bash hooks/tests/run-tests.sh
#
# Each test pipes sample hook input JSON into a hook script and checks the
# exit code and output. Git scenarios run inside throwaway repositories under
# a temporary directory, with a local bare repository acting as "origin", so
# no network access is needed.
#
# Sample credentials are assembled at runtime from fragments and random
# characters. This keeps realistic token strings out of the repository, where
# push protection and secret scanners would flag them.

set -u

tests_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
scripts_dir="$tests_dir/../scripts"
# shellcheck source-path=SCRIPTDIR source=../scripts/lib.sh
. "$scripts_dir/lib.sh"

SECRET="$scripts_dir/secret-guard.sh"
STOP="$scripts_dir/stop-unsaved-work.sh"
SESSION="$scripts_dir/session-behind-main.sh"

pass=0
fail=0
failures=""

ok() {
  pass=$((pass + 1))
  printf '  ok    %s\n' "$1"
}

not_ok() {
  fail=$((fail + 1))
  failures="$failures
  - $1"
  printf '  FAIL  %s\n' "$1"
  [ -n "${2:-}" ] && printf '        %s\n' "$2"
}

# Random characters drawn from a fixed alphabet. The leading "Ab1" makes sure
# the value has upper case, lower case, and a digit.
rand() {
  local n=$1 alphabet=${2:-A-Za-z0-9}
  local body
  body=$(LC_ALL=C tr -dc "$alphabet" </dev/urandom 2>/dev/null | head -c "$((n - 3))")
  printf 'Ab1%s' "$body"
}

rand_upper() {
  LC_ALL=C tr -dc 'A-Z0-9' </dev/urandom 2>/dev/null | head -c "$1"
}

prompt_json() {
  printf '{"session_id":"test","hook_event_name":"UserPromptSubmit","cwd":"/tmp","prompt":%s}' "$(json_str "$1")"
}

# Validates that the output is a single JSON object, when jq is available.
valid_json() {
  [ -z "$1" ] && return 0
  command -v jq >/dev/null 2>&1 || return 0
  printf '%s' "$1" | jq -e 'type == "object"' >/dev/null 2>&1
}

expect_block() {
  local name=$1 prompt=$2 expect_label=$3 secret=${4:-}
  local out rc
  out=$(prompt_json "$prompt" | bash "$SECRET")
  rc=$?
  if [ "$rc" -ne 0 ]; then
    not_ok "$name" "exit code $rc"
    return
  fi
  if ! valid_json "$out"; then
    not_ok "$name" "invalid JSON: $out"
    return
  fi
  case "$out" in
    *'"decision": "block"'* | *'"decision":"block"'*) ;;
    *)
      not_ok "$name" "not blocked: $out"
      return
      ;;
  esac
  case "$out" in
    *"$expect_label"*) ;;
    *)
      not_ok "$name" "missing label '$expect_label': $out"
      return
      ;;
  esac
  if [ -n "$secret" ]; then
    # Nothing beyond the first four characters of the secret may appear.
    local tail=${secret:4}
    case "$out" in
      *"$tail"*)
        not_ok "$name" "output leaks the secret"
        return
        ;;
    esac
  fi
  ok "$name"
}

expect_allow() {
  local name=$1 prompt=$2
  local out rc
  out=$(prompt_json "$prompt" | bash "$SECRET")
  rc=$?
  if [ "$rc" -eq 0 ] && [ -z "$out" ]; then
    ok "$name"
  else
    not_ok "$name" "rc=$rc out=$out"
  fi
}

run_secret_tests() {
  local aws_key gh_tok gh_pat ant oai oai_proj stripe slack google nvidia jwt
  aws_key="AK""IA$(rand_upper 16)"
  gh_tok="gh""p_$(rand 36)"
  gh_pat="github""_pat_$(rand 30)_$(rand 20)"
  ant="sk-""ant-api03-$(rand 40 'A-Za-z0-9_-')"
  oai="sk-$(rand 48)"
  oai_proj="sk-""proj-$(rand 40 'A-Za-z0-9_-')"
  stripe="sk""_live_$(rand 24)"
  slack="xo""xb-$(rand_upper 11)-$(rand 24)"
  google="AI""za$(rand 35 'A-Za-z0-9_-')"
  nvidia="nv""api-$(rand 40 'A-Za-z0-9_-')"
  jwt="ey""JhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.ey""J$(rand 40 'A-Za-z0-9_-').$(rand 30 'A-Za-z0-9_-')"
  local aws_secret
  aws_secret=$(rand 40 'A-Za-z0-9/+')
  local db_pw
  db_pw="Pg$(rand 14)"
  local pem_body
  pem_body=$(rand 64 'A-Za-z0-9+/')

  echo "secret-guard: positive cases"
  expect_block "AWS access key ID" "deploy with key $aws_key please" "AWS access key ID" "$aws_key"
  expect_block "AWS secret near aws_secret" "aws_secret_access_key = $aws_secret" "AWS secret access key" "$aws_secret"
  expect_block "GitHub classic token" "use token $gh_tok to push" "GitHub token" "$gh_tok"
  expect_block "GitHub fine-grained PAT" "token: $gh_pat" "GitHub token" "$gh_pat"
  expect_block "Anthropic key" "ANTHROPIC_API_KEY=$ant" "Anthropic API key" "$ant"
  expect_block "OpenAI legacy key" "my key is $oai" "OpenAI API key" "$oai"
  expect_block "OpenAI project key" "export OPENAI_API_KEY=$oai_proj" "OpenAI API key" "$oai_proj"
  expect_block "Stripe live key" "stripe key $stripe" "Stripe secret or restricted key" "$stripe"
  expect_block "Slack bot token" "slack $slack" "Slack token" "$slack"
  expect_block "Google API key" "maps key $google" "Google API key" "$google"
  expect_block "NVIDIA API key" "NVIDIA_API_KEY=$nvidia" "NVIDIA API key" "$nvidia"
  expect_block "Private key block" "here is my key
-----BEGIN OPENSSH PRIVATE KEY-----
$pem_body
-----END OPENSSH PRIVATE KEY-----" "private key block" "$pem_body"
  expect_block "JWT / Supabase key" "SUPABASE_SERVICE_ROLE_KEY=$jwt" "JWT" "$jwt"
  expect_block "Database URL with password" "connect to postgres://app:$db_pw@db.internal:5432/prod" "database URL" "$db_pw"
  expect_block "Password assignment" "the password=Hunt3r2!xyz for the admin" "password assignment"
  expect_block "Anthropic key is not reported as OpenAI" "key $ant" "Anthropic API key" "$ant"

  echo "secret-guard: negative cases"
  expect_allow "AWS docs example key" "set AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE as in the docs"
  expect_allow "AWS docs example secret" "aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
  expect_allow "Placeholder key" "OPENAI_API_KEY=sk-your-key-here-replace-me-now"
  expect_allow "Repeated-character placeholder" "token ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  expect_allow "Slug that starts with sk-" "see the sk-learn-tutorial-for-beginners page"
  expect_allow "Env var reference in DB URL" "postgres://app:\${DB_PASSWORD}@localhost/app"
  expect_allow "Local default DB URL" "postgres://postgres:postgres@localhost:5432/dev"
  expect_allow "Password from env" "password = os.environ['DB_PASSWORD']"
  expect_allow "Password in prose" "reset the password: forgotten flow is broken"
  expect_allow "PEM question without key material" "how do I parse a -----BEGIN RSA PRIVATE KEY----- header?"
  expect_allow "Ordinary prompt" "refactor the auth module and add tests"
  expect_allow "Plain https URL" "fetch https://example.com/path?x=1"

  echo "secret-guard: escape hatch"
  expect_allow "#allow-secret allows a real-looking key" "#allow-secret this is a revoked key $gh_tok"
}

# Git scenarios ------------------------------------------------------------

export GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com
export GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com

work=$(mktemp -d "${TMPDIR:-/tmp}/agentic-hooks-test.XXXXXX")
work=$(cd "$work" && pwd -P)
trap 'rm -rf "$work"' EXIT

g() { git -c init.defaultBranch=main -c advice.detachedHead=false "$@" >/dev/null 2>&1; }

# Creates a bare origin and a clone of it with one pushed commit on main.
# Prints nothing; uses the names $1/origin.git and $1/clone.
make_repo() {
  local base=$1
  mkdir -p "$base"
  g init --bare -b main "$base/origin.git"
  g init -b main "$base/seed"
  echo one >"$base/seed/a.txt"
  g -C "$base/seed" add a.txt
  g -C "$base/seed" commit -m init
  g -C "$base/seed" remote add origin "$base/origin.git"
  g -C "$base/seed" push -u origin main
  g clone "$base/origin.git" "$base/clone"
}

stop_json() {
  printf '{"session_id":"t","hook_event_name":"Stop","cwd":%s,"stop_hook_active":%s}' "$(json_str "$1")" "${2:-false}"
}

session_json() {
  printf '{"session_id":"t","hook_event_name":"SessionStart","source":"startup","cwd":%s}' "$(json_str "$1")"
}

expect_output() {
  local name=$1 out=$2 rc=$3
  shift 3
  if [ "$rc" -ne 0 ]; then
    not_ok "$name" "exit code $rc"
    return
  fi
  if [ -z "$out" ]; then
    not_ok "$name" "expected output, got none"
    return
  fi
  if ! valid_json "$out"; then
    not_ok "$name" "invalid JSON: $out"
    return
  fi
  local needle
  for needle in "$@"; do
    case "$out" in
      *"$needle"*) ;;
      *)
        not_ok "$name" "missing '$needle' in: $out"
        return
        ;;
    esac
  done
  ok "$name"
}

expect_silent() {
  local name=$1 out=$2 rc=$3
  if [ "$rc" -eq 0 ] && [ -z "$out" ]; then
    ok "$name"
  else
    not_ok "$name" "rc=$rc out=$out"
  fi
}

run_stop_tests() {
  echo "stop-unsaved-work"
  local base="$work/stop-$1" out rc
  make_repo "$base"
  local repo="$base/clone"

  out=$(stop_json "$repo" | bash "$STOP"); rc=$?
  expect_silent "clean and pushed repo is silent" "$out" "$rc"

  echo two >>"$repo/a.txt"
  echo new >"$repo/b.txt"
  echo staged >"$repo/c.txt"
  g -C "$repo" add c.txt
  out=$(stop_json "$repo" | bash "$STOP"); rc=$?
  expect_output "dirty repo reports counts" "$out" "$rc" \
    "systemMessage" "1 staged" "1 unstaged" "1 untracked"

  out=$(stop_json "$repo" true | bash "$STOP"); rc=$?
  expect_silent "stop_hook_active=true is silent" "$out" "$rc"

  g -C "$repo" add -A
  g -C "$repo" commit -m wip
  out=$(stop_json "$repo" | bash "$STOP"); rc=$?
  expect_output "unpushed commit is reported" "$out" "$rc" "1 commit(s) not pushed to origin/main"

  g -C "$repo" push
  g -C "$repo" checkout -b feature/x
  out=$(stop_json "$repo" | bash "$STOP"); rc=$?
  expect_output "branch without upstream is reported" "$out" "$rc" "no upstream branch"

  g -C "$repo" checkout main
  g -C "$repo" worktree add -b wt-branch "$base/wt"
  echo dirty >"$base/wt/d.txt"
  out=$(stop_json "$repo" | bash "$STOP"); rc=$?
  expect_output "dirty sibling worktree is listed" "$out" "$rc" "Other worktrees" "$base/wt" "1 untracked"

  out=$(stop_json "$work" | bash "$STOP"); rc=$?
  expect_silent "non-git directory is silent" "$out" "$rc"

  local start end
  start=$(date +%s)
  stop_json "$repo" | bash "$STOP" >/dev/null
  end=$(date +%s)
  if [ $((end - start)) -lt 2 ]; then ok "runs in under 2 seconds"; else not_ok "runs in under 2 seconds" "$((end - start))s"; fi

  out=$(stop_json "$repo" | AGENTIC_TOOLS_HOOKS_DISABLE=stop-unsaved-work bash "$STOP"); rc=$?
  expect_silent "disabled via AGENTIC_TOOLS_HOOKS_DISABLE" "$out" "$rc"
}

run_session_tests() {
  echo "session-behind-main"
  local base="$work/session-$1" out rc
  make_repo "$base"
  local repo="$base/clone"

  out=$(session_json "$repo" | bash "$SESSION"); rc=$?
  expect_silent "up to date is silent" "$out" "$rc"

  # Advance origin/main from a second clone.
  g clone "$base/origin.git" "$base/other"
  echo ahead >>"$base/other/a.txt"
  g -C "$base/other" commit -am ahead1
  echo ahead >>"$base/other/a.txt"
  g -C "$base/other" commit -am ahead2
  g -C "$base/other" push

  out=$(session_json "$repo" | bash "$SESSION"); rc=$?
  expect_output "behind upstream main is reported" "$out" "$rc" \
    "systemMessage" "additionalContext" "SessionStart" "2 commit(s) behind its upstream origin/main"

  if [ "$(git -C "$repo" rev-parse HEAD)" != "$(git -C "$repo" rev-parse origin/main)" ]; then
    ok "hook did not pull"
  else
    not_ok "hook did not pull" "HEAD moved to origin/main"
  fi

  g -C "$repo" checkout -b feature/y
  g -C "$repo" push -u origin feature/y
  out=$(session_json "$repo" | bash "$SESSION"); rc=$?
  expect_output "feature branch behind origin/main is reported" "$out" "$rc" "2 commit(s) behind origin/main"

  g -C "$repo" remote set-url origin "$base/missing.git"
  out=$(session_json "$repo" | bash "$SESSION"); rc=$?
  expect_silent "offline (fetch fails) is silent" "$out" "$rc"

  out=$(session_json "$work" | bash "$SESSION"); rc=$?
  expect_silent "non-git directory is silent" "$out" "$rc"

  # A fetch that hangs must be cut off by the timeout fallback.
  local start end
  start=$(date +%s)
  run_with_timeout 1 sleep 5
  end=$(date +%s)
  if [ $((end - start)) -lt 4 ]; then ok "run_with_timeout stops a slow command"; else not_ok "run_with_timeout stops a slow command" "$((end - start))s"; fi
}

for mode in jq nojq; do
  if [ "$mode" = "nojq" ]; then
    export AGENTIC_HOOKS_NO_JQ=1
  else
    if ! command -v jq >/dev/null 2>&1; then
      echo "(jq not installed; skipping the jq pass)"
      continue
    fi
    export AGENTIC_HOOKS_NO_JQ=0
  fi
  echo "=== pass: $mode ==="
  run_secret_tests
  run_stop_tests "$mode"
  run_session_tests "$mode"
done

echo
echo "passed: $pass  failed: $fail"
if [ "$fail" -gt 0 ]; then
  printf 'failures:%s\n' "$failures"
  exit 1
fi
exit 0
