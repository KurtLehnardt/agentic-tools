# shellcheck shell=bash
# Shared helpers for the agentic-tools hook scripts.
# This file is sourced, not executed. It must stay compatible with the
# bash 3.2 that ships with macOS, so it avoids associative arrays,
# mapfile, and case-modification expansions.

# Returns success when jq is usable. Setting AGENTIC_HOOKS_NO_JQ=1 forces
# the pure-bash fallback, which the test suite uses to exercise that path.
have_jq() {
  [ "${AGENTIC_HOOKS_NO_JQ:-0}" != "1" ] && command -v jq >/dev/null 2>&1
}

# Returns success when the named hook has been disabled through the
# AGENTIC_TOOLS_HOOKS_DISABLE environment variable. The variable holds a
# comma-separated list of hook names, or the word "all".
hook_disabled() {
  local name=$1 list=",${AGENTIC_TOOLS_HOOKS_DISABLE:-},"
  case "$list" in
    *",all,"* | *",$name,"*) return 0 ;;
  esac
  return 1
}

# Prints the value of a top-level key from the JSON document in $1.
# Strings are printed unquoted, booleans and numbers as their literal text,
# and a missing key prints nothing. The fallback parser only understands
# flat scalar values, which is all these hooks need.
json_get() {
  local doc=$1 key=$2
  if have_jq; then
    printf '%s' "$doc" | jq -r --arg k "$key" '.[$k] // empty | tostring' 2>/dev/null
    return 0
  fi
  local raw
  raw=$(printf '%s' "$doc" | tr '\n' ' ' |
    grep -oE "\"$key\"[[:space:]]*:[[:space:]]*(\"([^\"\\\\]|\\\\.)*\"|true|false|null|-?[0-9.]+)" |
    head -n 1 |
    sed -E "s/^\"$key\"[[:space:]]*:[[:space:]]*//")
  case "$raw" in
    \"*\")
      raw=${raw#\"}
      raw=${raw%\"}
      raw=${raw//\\\//\/}
      raw=${raw//\\\"/\"}
      raw=${raw//\\\\/\\}
      ;;
    null) raw="" ;;
  esac
  printf '%s' "$raw"
}

# Prints $1 as a quoted JSON string literal.
json_str() {
  if have_jq; then
    printf '%s' "$1" | jq -Rs .
    return 0
  fi
  local s=$1
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\n'/\\n}
  s=${s//$'\r'/\\r}
  s=${s//$'\t'/\\t}
  printf '"%s"' "$s"
}

# Runs a command with a time limit in seconds. It prefers timeout or
# gtimeout and otherwise falls back to a background watcher that kills the
# command. The watcher's output is detached so that a leftover sleep
# process cannot hold the hook's stdout open.
run_with_timeout() {
  local secs=$1
  shift
  if command -v timeout >/dev/null 2>&1; then
    timeout "$secs" "$@"
    return $?
  fi
  if command -v gtimeout >/dev/null 2>&1; then
    gtimeout "$secs" "$@"
    return $?
  fi
  "$@" &
  local pid=$!
  (
    # The sleep runs as its own child so that the trap can end it early
    # when the command finishes first.
    sleep "$secs" &
    sleeper=$!
    trap 'kill "$sleeper" 2>/dev/null; exit 0' TERM
    wait "$sleeper"
    kill -TERM "$pid" 2>/dev/null
  ) >/dev/null 2>&1 &
  local watcher=$!
  wait "$pid" 2>/dev/null
  local rc=$?
  kill "$watcher" 2>/dev/null
  wait "$watcher" 2>/dev/null
  return $rc
}
