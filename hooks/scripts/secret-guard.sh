#!/usr/bin/env bash
# UserPromptSubmit hook: blocks a prompt that appears to contain a credential.
#
# The prompt is scanned for well-known key formats (AWS, GitHub, Anthropic,
# OpenAI, Stripe, Slack, Google, NVIDIA), private key blocks, JWTs such as
# Supabase keys, database URLs with an inline password, and password
# assignments. When one is found, the prompt is blocked before it reaches
# Claude, and the reason names the type of credential that was detected.
#
# The reason never repeats the secret. It shows at most the first four
# characters of the match, which is the non-secret prefix or keyword, and
# the length of the secret value.
#
# A prompt that contains the literal text #allow-secret is always allowed.
# Obvious documentation examples and placeholders are ignored.

set -u

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source-path=SCRIPTDIR source=lib.sh
. "$script_dir/lib.sh"

hook_disabled secret-guard && exit 0

input=$(cat)
if have_jq; then
  prompt=$(printf '%s' "$input" | jq -r '.prompt // empty' 2>/dev/null)
else
  # Without jq the raw JSON is scanned. Escaped newlines appear as the two
  # characters \n, which the patterns below tolerate.
  prompt=$input
fi

[ -z "$prompt" ] && exit 0

case "$prompt" in
  *"#allow-secret"*) exit 0 ;;
esac

lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

# Returns success when the value looks like a placeholder or an example
# rather than a real secret.
is_placeholder() {
  local v l
  v=$1
  l=$(lower "$v")
  case "$l" in
    *example* | *your* | *xxxx* | *placeholder* | *redacted* | *changeme* | \
      *dummy* | *fake* | *sample* | *here* | *insert* | *replace* | \
      *"<"* | *">"* | *"..."* | *"***"* | *"…"*)
      return 0
      ;;
  esac
  case "$v" in
    '$'* | '{'* | '%'*) return 0 ;;
  esac
  # A value made of very few distinct characters, such as aaaaaaaa or
  # 0000-0000, is a placeholder.
  local distinct
  distinct=$(printf '%s' "$v" | fold -w1 | sort -u | wc -l | tr -d ' ')
  [ "${distinct:-0}" -lt 6 ] && return 0
  return 1
}

# Returns success when the value contains an upper case letter, a lower
# case letter, and a digit, which random API keys almost always do.
looks_random() {
  case "$1" in *[A-Z]*) ;; *) return 1 ;; esac
  case "$1" in *[a-z]*) ;; *) return 1 ;; esac
  case "$1" in *[0-9]*) ;; *) return 1 ;; esac
  return 0
}

# Extra checks for types where the bare pattern is too loose. The first
# argument is the type id, the second the extracted secret value.
passes_type_check() {
  local type=$1 v=$2 l
  case "$type" in
    openai)
      case "$v" in sk-ant-*) return 1 ;; esac
      looks_random "${v#sk-}" || return 1
      ;;
    db_url)
      l=$(lower "$v")
      case "$l" in
        password | passwd | pass | pw | pwd | secret | postgres | root | admin | user | test) return 1 ;;
      esac
      ;;
    password)
      l=$(lower "$v")
      [ "${#v}" -lt 6 ] && return 1
      case "$l" in
        *env* | *secret* | *vault* | *process.* | *os.* | *config* | \
          true | false | null | none | required | optional) return 1 ;;
      esac
      # Plain words are usually prose ("password: forgotten"), so require
      # at least one character that is not a letter.
      case "$v" in *[!A-Za-z]*) ;; *) return 1 ;; esac
      ;;
  esac
  return 0
}

found_types=""
first_mask=""

record() {
  local label=$1 match=$2 value=$3
  case "$found_types" in
    *"$label"*) ;;
    *) found_types="${found_types:+$found_types, }$label" ;;
  esac
  if [ -z "$first_mask" ]; then
    first_mask="starts with \"${match:0:4}\", secret length ${#value}"
  fi
}

# Scans the prompt for one pattern.
#   $1 type id, $2 human label, $3 "i" for case-insensitive or "-",
#   $4 extended regex, $5 optional sed -E expression that extracts the
#   secret value from the full match.
scan() {
  local type=$1 label=$2 icase=$3 re=$4 extract=${5:-}
  local flags=-oE
  [ "$icase" = "i" ] && flags=-oiE
  local matches m v
  matches=$(printf '%s\n' "$prompt" | grep $flags -- "$re" 2>/dev/null) || return 0
  while IFS= read -r m; do
    [ -z "$m" ] && continue
    v=$m
    [ -n "$extract" ] && v=$(printf '%s' "$m" | sed -E "$extract")
    # Strip quotes and trailing punctuation that the pattern may include.
    v=${v%\"}; v=${v#\"}; v=${v%\'}; v=${v#\'}
    v=${v%,}; v=${v%;}; v=${v%\"}; v=${v%\'}
    is_placeholder "$v" && continue
    passes_type_check "$type" "$v" || continue
    record "$label" "$m" "$v"
    return 0
  done <<EOF
$matches
EOF
  return 0
}

scan aws_key "AWS access key ID" - '(AKIA|ASIA)[0-9A-Z]{16}'
scan aws_secret "AWS secret access key" i \
  'aws_?secret(_access)?(_key)?["'\'']?[[:space:]]*[:=][[:space:]]*["'\'']?[A-Za-z0-9/+=]{40}' \
  's/.*(.{40})$/\1/'
scan github "GitHub token" - 'gh[pousr]_[A-Za-z0-9]{36,}'
scan github "GitHub token" - 'github_pat_[A-Za-z0-9_]{22,}'
scan anthropic "Anthropic API key" - 'sk-ant-[A-Za-z0-9_-]{20,}'
scan openai "OpenAI API key" - 'sk-(proj-)?[A-Za-z0-9_-]{20,}'
scan stripe "Stripe secret or restricted key" - '(sk|rk)_(live|test)_[A-Za-z0-9]{10,}'
scan slack "Slack token" - 'xox[baprs]-[A-Za-z0-9-]{10,}'
scan google "Google API key" - 'AIza[0-9A-Za-z_-]{35}'
scan nvidia "NVIDIA API key" - 'nvapi-[A-Za-z0-9_-]{20,}'
scan jwt "JWT (for example a Supabase key)" - \
  'eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'
scan db_url "database URL with an inline password" i \
  '[a-z][a-z0-9+.-]*://[^:/[:space:]@"]+:[^@[:space:]"/]+@' \
  's#^[^:]+://[^:]+:(.*)@$#\1#'
scan password "password assignment" i \
  'password["'\'']?[[:space:]]*[:=][[:space:]]*[^[:space:]]+' \
  's/^[^:=]*[:=][[:space:]]*//'

# A private key header only counts when key material follows it, so that
# questions about the PEM format are not blocked.
if printf '%s\n' "$prompt" | grep -qE -- '-----BEGIN [A-Z ]*PRIVATE KEY-----'; then
  if printf '%s\n' "$prompt" | sed -E 's/-----[A-Z ]+-----//g' | grep -qE '[A-Za-z0-9+/=]{40,}'; then
    header=$(printf '%s\n' "$prompt" | grep -oE -- '-----BEGIN [A-Z ]*PRIVATE KEY-----' | head -n 1)
    [ -z "$first_mask" ] && first_mask="starts with \"${header:0:4}\", key material follows the header"
    record "private key block" "$header" "$prompt"
  fi
fi

[ -z "$found_types" ] && exit 0

reason="Blocked: this prompt appears to contain a credential ($found_types; $first_mask). It was not sent to Claude. If the credential is real, rotate it now, because it may already be in your terminal scrollback or shell history. Keep secrets in environment variables or your shell profile and refer to them by name instead of pasting them. If this is a false positive, resend the prompt with #allow-secret anywhere in it."

printf '{"decision": "block", "reason": %s}\n' "$(json_str "$reason")"
exit 0
