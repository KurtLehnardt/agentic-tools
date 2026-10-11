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

# Prints the current time in milliseconds. It uses perl or python3 when one
# is available and otherwise whole seconds from date.
now_ms() {
  if command -v perl >/dev/null 2>&1; then
    perl -MTime::HiRes=time -e 'printf "%d\n", time * 1000'
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c 'import time; print(int(time.time() * 1000))'
  else
    echo "$(($(date +%s) * 1000))"
  fi
}

# Writes hook input JSON whose prompt is the content of file $1 to file $2.
# The escaping is done by awk so that building a large prompt stays fast and
# does not depend on jq.
file_prompt_json() {
  awk 'BEGIN { printf "{\"session_id\":\"test\",\"hook_event_name\":\"UserPromptSubmit\",\"cwd\":\"/tmp\",\"prompt\":\"" }
    { gsub(/\\/, "\\\\"); gsub(/"/, "\\\""); gsub(/\t/, "\\t"); printf "%s\\n", $0 }
    END { printf "\"}" }' "$1" >"$2"
}

# Runs the secret guard on the prompt in file $2 and checks that it blocks
# with label $4 within $3 milliseconds.
timed_block() {
  local name=$1 file=$2 limit=$3 label=$4 start end out
  file_prompt_json "$file" "$file.json"
  start=$(now_ms)
  out=$(bash "$SECRET" <"$file.json")
  end=$(now_ms)
  case "$out" in
    *'"decision": "block"'*"$label"*) ;;
    *)
      not_ok "$name" "not blocked: ${out:0:200}"
      return
      ;;
  esac
  if [ $((end - start)) -lt "$limit" ]; then
    ok "$name ($((end - start))ms)"
  else
    not_ok "$name" "took $((end - start))ms"
  fi
}

# Runs the secret guard on the prompt in file $2 and checks that it allows
# the prompt within $3 milliseconds.
timed_allow() {
  local name=$1 file=$2 limit=$3 start end out
  file_prompt_json "$file" "$file.json"
  start=$(now_ms)
  out=$(bash "$SECRET" <"$file.json")
  end=$(now_ms)
  if [ -n "$out" ]; then
    not_ok "$name" "unexpected block: ${out:0:200}"
    return
  fi
  if [ $((end - start)) -lt "$limit" ]; then
    ok "$name ($((end - start))ms)"
  else
    not_ok "$name" "took $((end - start))ms"
  fi
}

run_secret_tests() {
  local aws_key gh_tok gh_pat ant oai oai_proj stripe slack google nvidia jwt
  aws_key="AK""IA$(rand_upper 16)"
  gh_tok="gh""p_$(rand 36)"
  gh_pat="github""_pat_$(rand 30)_$(rand 20)"
  ant="sk-""ant-api03-$(rand 40 'A-Za-z0-9_-')"
  oai="sk-$(rand 48)"
  oai_proj="sk-""proj-$(rand 40)"
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

  local supa whsec hf glpat env_val
  supa="sb_""secret_$(rand 32 'A-Za-z0-9_-')"
  whsec="wh""sec_$(rand 32)"
  hf="h""f_$(rand 34)"
  glpat="gl""pat-$(rand 20 'A-Za-z0-9_-')"
  env_val=$(rand 32)
  expect_block "Bare AWS secret near AWS context" "aws configure gave me these
$aws_key
$aws_secret" "AWS secret access key" "$aws_secret"
  expect_block "Bare AWS secret on its own after an aws line" "my aws creds:
secret: $aws_secret" "AWS secret access key" "$aws_secret"
  expect_block "Supabase secret key" "SUPABASE_SECRET=$supa" "Supabase secret key" "$supa"
  expect_block "Stripe webhook secret" "the webhook secret is $whsec" "Stripe webhook signing secret" "$whsec"
  expect_block "Hugging Face token" "login with $hf" "Hugging Face token" "$hf"
  expect_block "GitLab PAT" "git clone https://oauth2:$glpat@gitlab.com/x/y.git" "GitLab personal access token" "$glpat"
  expect_block "Generic .env SECRET" "JWT_SECRET=$env_val" "secret environment variable" "$env_val"
  expect_block "Generic .env TOKEN with quotes" "export CI_DEPLOY_TOKEN=\"$env_val\"" "secret environment variable" "$env_val"
  expect_block "Generic .env SERVICE_ROLE" "SUPABASE_SERVICE_ROLE_KEY = $env_val" "secret environment variable" "$env_val"
  expect_block "Generic .env PRIVATE_KEY" "APP_PRIVATE_KEY=$env_val" "secret environment variable" "$env_val"
  expect_block "Quoted password literal" "const password = \"Hunt3r2!xyz\";" "password assignment"

  echo "secret-guard: block output"
  local out
  # The reason may show the fixed prefix of a key format but no character
  # after it. The sample values all start with "Ab1" after the prefix.
  out=$(prompt_json "login with $hf" | bash "$SECRET")
  case "$out" in
    *'starts with \"hf_\"'*) case "$out" in *"${hf:0:4}"*) not_ok "hf_ reason shows no character after the prefix" "$out" ;; *) ok "hf_ reason shows no character after the prefix" ;; esac ;;
    *) not_ok "hf_ reason shows no character after the prefix" "$out" ;;
  esac
  out=$(prompt_json "my key is $oai" | bash "$SECRET")
  case "$out" in
    *'starts with \"sk-\"'*) case "$out" in *"${oai:0:4}"*) not_ok "legacy sk- reason shows no character after the prefix" "$out" ;; *) ok "legacy sk- reason shows no character after the prefix" ;; esac ;;
    *) not_ok "legacy sk- reason shows no character after the prefix" "$out" ;;
  esac
  out=$(prompt_json "use token $gh_tok" | bash "$SECRET")
  case "$out" in
    *'"suppressOriginalPrompt": true'* | *'"suppressOriginalPrompt":true'*)
      case "$out" in
        *'"hookEventName": "UserPromptSubmit"'* | *'"hookEventName":"UserPromptSubmit"'*) ok "block output sets suppressOriginalPrompt" ;;
        *) not_ok "block output sets suppressOriginalPrompt" "missing hookEventName: $out" ;;
      esac
      ;;
    *) not_ok "block output sets suppressOriginalPrompt" "$out" ;;
  esac
  if command -v jq >/dev/null 2>&1; then
    if printf '%s' "$out" | jq -e '.hookSpecificOutput.suppressOriginalPrompt == true and .decision == "block"' >/dev/null 2>&1; then
      ok "block output parses with suppressOriginalPrompt true"
    else
      not_ok "block output parses with suppressOriginalPrompt true" "$out"
    fi
  fi

  echo "secret-guard: performance"
  local big i real_pw
  real_pw="Pg$(rand 14)"
  big="$work/decoys-$AGENTIC_HOOKS_NO_JQ.txt"
  i=0
  : >"$big"
  while [ "$i" -lt 1000 ]; do
    printf 'line %d DATABASE_URL=postgres://app:postgres@db:5432/app_%d  # local default\n' "$i" "$i"
    i=$((i + 1))
  done >>"$big"
  printf 'and the real one: postgres://app:%s@db.internal:5432/prod\n' "$real_pw" >>"$big"
  timed_block "~70KB paste with 1000 decoy DB URLs blocks in under 3s" "$big" 3000 "database URL"

  big="$work/big-$AGENTIC_HOOKS_NO_JQ.txt"
  awk 'BEGIN { for (i = 0; i < 9000; i++) printf "const password = req.body.password; let token = getToken(user.id); // see https://example.com/x?y=%d task-list\n", i }' |
    head -c 1048576 >"$big"
  timed_allow "1MB code paste is scanned in under 2s" "$big" 2000

  big="$work/big2-$AGENTIC_HOOKS_NO_JQ.txt"
  awk 'BEGIN { for (i = 0; i < 18000; i++) printf "const password = req.body.password; let token = getToken(user.id); // see https://example.com/x?y=%d task-list\n", i }' |
    head -c 2097152 >"$big"
  timed_allow "2MB code paste is scanned in under 3s" "$big" 3000

  echo "secret-guard: candidate limits never fail open"
  # Each of these prompts has more than 5000 decoys for one rule followed by
  # a real credential. Decoys that fail the cheap checks must not use up the
  # candidate limit, so the real credential is still found.
  local lim
  lim="$work/lim-tasks-$AGENTIC_HOOKS_NO_JQ.txt"
  awk 'BEGIN { for (i = 0; i < 5200; i++) printf "- [ ] task-%d\n", i }' >"$lim"
  printf 'my key is %s\n' "$oai" >>"$lim"
  timed_block "5200 task-N lines then a real sk- key blocks" "$lim" 3000 "OpenAI API key"
  lim="$work/lim-pw-$AGENTIC_HOOKS_NO_JQ.txt"
  awk 'BEGIN { for (i = 0; i < 5200; i++) printf "password: ${PW_%d}\n", i }' >"$lim"
  printf 'password: Hunt3r2!xyz\n' >>"$lim"
  timed_block "5200 password: \${PW_N} lines then a real password blocks" "$lim" 3000 "password assignment"
  lim="$work/lim-urls-$AGENTIC_HOOKS_NO_JQ.txt"
  awk 'BEGIN { for (i = 0; i < 5200; i++) printf "see https://user:x@host%d.local/\n", i }' >"$lim"
  printf 'connect to postgres://app:%s@db.internal:5432/prod\n' "$db_pw" >>"$lim"
  timed_block "5200 user:x@ URLs then a real DB URL password blocks" "$lim" 3000 "database URL"
  lim="$work/lim-tf-$AGENTIC_HOOKS_NO_JQ.txt"
  awk 'BEGIN { for (i = 0; i < 1700; i++) printf "resource \"aws_s3_bucket\" \"b%d\" {\n  bucket = \"my-bucket-%d\"\n}\n", i, i }' |
    head -c 84000 >"$lim"
  printf '\n%s\n' "$aws_secret" >>"$lim"
  timed_block "84KB Terraform paste with aws_ then a bare AWS secret blocks" "$lim" 3000 "AWS secret access key"
  # When a limit is reached, the prompt is blocked rather than let through.
  lim="$work/lim-many-$AGENTIC_HOOKS_NO_JQ.txt"
  awk 'BEGIN { for (i = 0; i < 5100; i++) printf "token %d: ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\n", i }' >"$lim"
  timed_block "5100 plausible placeholder tokens block as too large to scan" "$lim" 3000 "too large to scan fully for secrets"
  lim="$work/lim-dense-$AGENTIC_HOOKS_NO_JQ.txt"
  awk 'BEGIN { for (i = 0; i < 400000; i++) printf "sk-a task-b " }' | head -c 4194304 >"$lim"
  timed_block "4MB single line of dense decoys blocks as too large within 5s" "$lim" 5000 "too large to scan fully for secrets"
  lim="$work/lim-allow-$AGENTIC_HOOKS_NO_JQ.txt"
  awk 'BEGIN { print "#allow-secret"; for (i = 0; i < 5100; i++) printf "token %d: ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\n", i }' >"$lim"
  timed_allow "#allow-secret allows a prompt that is too large to scan" "$lim" 3000

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

  echo "secret-guard: code that is not a credential"
  expect_allow "password from req.body" "const password = req.body.password;"
  expect_allow "password from a function call" "password = hashPassword(input, salt)"
  expect_allow "password schema definition" "password: z.string().min(8)"
  expect_allow "password from getpass" "password=getpass.getpass()"
  expect_allow "sk- package-style slug" "pip install sk-learn-RandomForestClassifier2"
  expect_allow "password typed as a variable" "password: String,
  userPassword = newPassword"
  expect_allow "Supabase publishable key" "NEXT_PUBLIC_SUPABASE_KEY=sb_publishable_$(rand 32)"
  expect_allow "Env secret that references another variable" "API_KEY=\${OPENAI_API_KEY}"
  expect_allow "Password from \${VAR:-default} expansion" "password=\${MAC_IMAGE_PASSWORD:-admin}"
  expect_allow "Exported password from \${VAR:-default} expansion" "export password=\${MAC_IMAGE_PASSWORD:-admin}"
  expect_allow "Password \${VAR:-default} with a mixed default" "PASSWORD=\${MAC_IMAGE_PASSWORD:-adm1n!x}"
  expect_allow "Password from \${VAR:=default} expansion" "echo \${DB_PASSWORD:=Hunt3r2xyz9}"
  expect_allow "Env token that is a number" "TOKEN_TTL_SECONDS=3600"
  expect_allow "Env secret that is a slug" "SECRET_NAME=prod/app/db-credentials-v2"
  expect_allow "Env secret that is too short" "SECRET_KEY=Ab1cd"
  expect_allow "Env secret placeholder" "STRIPE_SECRET_KEY=your-stripe-secret-key-here"
  expect_allow "40-character string without AWS context" "commit message id: $(rand 40 'A-Za-z0-9/+')"
  expect_allow "Git SHA near AWS context" "aws deploy at commit $(LC_ALL=C tr -dc 'a-f0-9' </dev/urandom | head -c 40)"

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
  expect_silent "new branch with no local-only commits is silent" "$out" "$rc"

  echo x >"$repo/x.txt"
  g -C "$repo" add x.txt
  g -C "$repo" commit -m x
  out=$(stop_json "$repo" | bash "$STOP"); rc=$?
  expect_output "branch without upstream is reported" "$out" "$rc" "no upstream branch (1 commit(s) not on any remote)"

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

  # A repository with commits but no remote has nothing to push to.
  local solo="$base/solo"
  g init -b main "$solo"
  echo one >"$solo/a.txt"
  g -C "$solo" add a.txt
  g -C "$solo" commit -m init
  g -C "$solo" checkout -b feature/local
  echo two >"$solo/b.txt"
  g -C "$solo" add b.txt
  g -C "$solo" commit -m two
  out=$(stop_json "$solo" | bash "$STOP"); rc=$?
  expect_silent "local-only repo with no remote is silent" "$out" "$rc"
  echo dirty >>"$solo/a.txt"
  out=$(stop_json "$solo" | bash "$STOP"); rc=$?
  expect_output "local-only repo still reports uncommitted changes" "$out" "$rc" "1 unstaged"
  case "$out" in
    *"no upstream"*) not_ok "local-only repo does not mention a missing upstream" "$out" ;;
    *) ok "local-only repo does not mention a missing upstream" ;;
  esac

  # A fresh repository with no commits (an unborn branch) has nothing to
  # push, but its uncommitted files are still reported.
  local empty="$base/empty"
  g init -b main "$empty"
  out=$(stop_json "$empty" | bash "$STOP"); rc=$?
  expect_silent "unborn repo with no files is silent" "$out" "$rc"
  echo new >"$empty/new.txt"
  echo staged >"$empty/staged.txt"
  g -C "$empty" add staged.txt
  g -C "$empty" remote add origin "$base/origin.git"
  out=$(stop_json "$empty" | bash "$STOP"); rc=$?
  expect_output "unborn repo with files reports counts" "$out" "$rc" "(main): uncommitted changes (1 staged, 1 untracked)"
  case "$out" in
    *"upstream"* | *"not pushed"* | *"remote"*) not_ok "unborn repo has no push note" "$out" ;;
    *) ok "unborn repo has no push note" ;;
  esac

  # Agent worktrees under .claude/worktrees/ are not listed.
  local many="$base/many"
  make_repo "$many"
  echo ".claude/" >>"$many/clone/.git/info/exclude"
  g -C "$many/clone" worktree add -b agent-1 "$many/clone/.claude/worktrees/agent-1"
  echo dirty >"$many/clone/.claude/worktrees/agent-1/d.txt"
  out=$(stop_json "$many/clone" | bash "$STOP"); rc=$?
  expect_silent "dirty agent worktree under .claude/worktrees/ is skipped" "$out" "$rc"

  # Many dirty sibling worktrees: the scan is capped and stays fast.
  local n=0
  while [ "$n" -lt 25 ]; do
    g -C "$many/clone" worktree add -b "wt-$n" "$many/wt-$n"
    echo dirty >"$many/wt-$n/d.txt"
    n=$((n + 1))
  done
  local start_ms end_ms
  start_ms=$(now_ms)
  out=$(stop_json "$many/clone" | bash "$STOP"); rc=$?
  end_ms=$(now_ms)
  expect_output "25 dirty worktrees are summarized" "$out" "$rc" "Other worktrees" "and 5 more worktree(s)"
  if [ $((end_ms - start_ms)) -lt 1000 ]; then
    ok "25 worktrees scanned in under 1s ($((end_ms - start_ms))ms)"
  else
    not_ok "25 worktrees scanned in under 1s" "$((end_ms - start_ms))ms"
  fi
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

  # The user's core.sshCommand must be kept, with the batch options added.
  local fake_ssh="$base/fake-ssh" ssh_log="$base/ssh.log"
  printf '#!/bin/sh\nprintf "%%s\\n" "$*" >>"%s"\nexit 255\n' "$ssh_log" >"$fake_ssh"
  chmod +x "$fake_ssh"
  g -C "$repo" remote set-url origin "git@fakehost.invalid:org/repo.git"
  g -C "$repo" config core.sshCommand "$fake_ssh -o UserOption=kept"
  : >"$ssh_log"
  out=$(session_json "$repo" | env -u GIT_SSH_COMMAND bash "$SESSION"); rc=$?
  expect_silent "ssh fetch failure is silent" "$out" "$rc"
  case "$(cat "$ssh_log")" in
    *"UserOption=kept"*"BatchMode=yes"*"ConnectTimeout="*) ok "core.sshCommand is preserved and batch options appended" ;;
    *) not_ok "core.sshCommand is preserved and batch options appended" "ssh log: $(cat "$ssh_log")" ;;
  esac
  : >"$ssh_log"
  out=$(session_json "$repo" | GIT_SSH_COMMAND="$fake_ssh -o EnvOption=kept" bash "$SESSION"); rc=$?
  case "$(cat "$ssh_log")" in
    *"EnvOption=kept"*"BatchMode=yes"*) ok "GIT_SSH_COMMAND is preserved and batch options appended" ;;
    *) not_ok "GIT_SSH_COMMAND is preserved and batch options appended" "ssh log: $(cat "$ssh_log")" ;;
  esac
  g -C "$repo" config --unset core.sshCommand

  # A plain GIT_SSH program, with no ssh command configured, is left alone.
  : >"$ssh_log"
  out=$(session_json "$repo" | env -u GIT_SSH_COMMAND GIT_SSH="$fake_ssh" bash "$SESSION"); rc=$?
  expect_silent "ssh fetch failure with GIT_SSH is silent" "$out" "$rc"
  case "$(cat "$ssh_log")" in
    *"BatchMode=yes"*) not_ok "GIT_SSH alone is not overridden" "ssh log: $(cat "$ssh_log")" ;;
    *fakehost.invalid*) ok "GIT_SSH alone is not overridden" ;;
    *) not_ok "GIT_SSH alone is not overridden" "GIT_SSH was not used; ssh log: $(cat "$ssh_log")" ;;
  esac

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
