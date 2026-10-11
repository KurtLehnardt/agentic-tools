#!/usr/bin/env bash
# UserPromptSubmit hook: blocks a prompt that appears to contain a credential.
#
# The prompt is scanned for well-known key formats (AWS, GitHub, GitLab,
# Anthropic, OpenAI, Stripe, Slack, Google, NVIDIA, Hugging Face, Supabase),
# private key blocks, JWTs, database URLs with an inline password, password
# assignments, and secret-looking environment variable assignments. When one
# is found, the prompt is blocked before it reaches Claude, and the reason
# names the type of credential that was detected.
#
# The reason never repeats the secret. It shows at most the fixed, publicly
# known prefix of the key format (for example ghp_ or hf_), never any
# character after that prefix, and the length of the secret value. The block output also sets
# suppressOriginalPrompt, so Claude Code leaves the prompt text out of the
# block message.
#
# A prompt that contains the literal text #allow-secret is always allowed.
# Obvious documentation examples and placeholders are ignored.
#
# All scanning happens in a single awk process with no per-match forks. Every
# rule is guarded by a cheap literal prefilter, and long lines are scanned in
# bounded chunks. Two limits keep the scan fast on huge pastes: each rule may
# examine at most MAXM plausible candidates (matches that pass the cheap
# boundary and length checks), and the total amount of text rescanned after
# matches is capped at MAXWORK characters. The scan never fails open: when
# either limit is reached, the prompt is blocked with a reason asking the
# user to add #allow-secret if it contains no credentials. The awk program
# uses only POSIX features (no interval expressions, no gawk extensions), so
# it runs on the BSD awk in macOS, gawk, mawk, and busybox.

set -u

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source-path=SCRIPTDIR source=lib.sh
. "$script_dir/lib.sh"

hook_disabled secret-guard && exit 0

input=$(cat)
[ -z "$input" ] && exit 0

# The awk program prints nothing when the prompt is clean. Otherwise it
# prints one line: the detected labels joined by ", ", a tab, and a short
# description of the first match that never includes the secret itself.
# When a scan limit was reached and nothing was found, it prints the marker
# @toolarge instead of the labels.
read -r -d '' SCANNER <<'AWK'
function lc(s) { return tolower(s) }

# Returns 1 when the value looks like a placeholder or an example rather
# than a real secret.
function is_placeholder(v,    l, n, i, c, seen, distinct) {
  l = tolower(v)
  if (l ~ /example|your|xxxx|placeholder|redacted|changeme|dummy|fake|sample|here|insert|replace|<|>|\.\.\.|\*\*\*/) return 1
  if (index(v, "\342\200\246")) return 1
  c = substr(v, 1, 1)
  if (c == "$" || c == "{" || c == "%") return 1
  # A value made of very few distinct characters, such as aaaaaaaa or
  # 0000-0000, is a placeholder. Only the first 64 characters are counted.
  n = length(v); if (n > 64) n = 64
  distinct = 0
  for (i = 1; i <= n; i++) {
    c = substr(v, i, 1)
    if (!(c in seen)) { seen[c] = 1; distinct++; if (distinct >= 6) return 0 }
  }
  return 1
}

# Returns 1 when the value has an upper case letter, a lower case letter,
# and a digit, which random API keys almost always do.
function looks_random(v) {
  return (v ~ /[A-Z]/ && v ~ /[a-z]/ && v ~ /[0-9]/)
}

# Returns 1 when the value reads like code rather than a literal: a call,
# a member access such as req.body.password, or a reference to the
# environment or to configuration.
function is_code_expr(v,    l) {
  if (v ~ /[()]/) return 1
  if (v ~ /^[A-Za-z_$][A-Za-z0-9_$]*(\.|->|::)[A-Za-z_$]/) return 1
  if (v ~ /^[$%{[@]/) return 1
  l = tolower(v)
  if (l ~ /^(req|request|this|self|process|os|env|config|cfg|settings|params|args|opts|options|props|ctx|data|form|input|body|user|values)[.\[]/) return 1
  if (l ~ /getenv|environ|process\.env|secrets\.|vault/) return 1
  return 0
}

# Returns 1 when the character before position pos in s can start a token,
# so that a prefix such as sk- inside a longer word such as task-list is not
# treated as a key.
function boundary_ok(s, pos, abs_prev,    c) {
  if (pos > 1) c = substr(s, pos - 1, 1)
  else c = abs_prev
  return (c !~ /[A-Za-z0-9]/)
}

# Strips matching quotes and trailing punctuation from a value.
function clean(v) {
  sub(/[,;]+$/, "", v)
  if (v ~ /^["'`]/) v = substr(v, 2)
  if (v ~ /["'`]$/) v = substr(v, 1, length(v) - 1)
  sub(/[,;]+$/, "", v)
  return v
}

# Records a detection. prefix is the fixed, publicly known prefix of the
# key format, or "" when nothing about the match may be shown. It must never
# include a character of the secret itself.
function record(type, label, prefix, value_len) {
  if (!(label in labels_seen)) {
    labels_seen[label] = 1
    found = (found == "") ? label : found ", " label
  }
  if (first_mask == "") {
    if (type == "private_key") first_mask = "key material follows the header"
    else if (prefix != "") first_mask = "starts with \"" prefix "\", secret length " value_len
    else first_mask = "secret length " value_len
  }
  done[type] = 1
}

# Returns 1 when the keyword at position p in s is part of a variable name
# inside a shell expansion such as ${DB_PASSWORD:-admin} or
# ${API_TOKEN=abc}, which is code rather than a literal.
function in_expansion(s, p,    from, pre) {
  from = p - 128; if (from < 1) from = 1
  pre = substr(s, from, p - from)
  return (pre ~ /\$\{[A-Za-z0-9_]*$/)
}

# Checks one candidate match. t is the rule id, m the full match, s the
# chunk it was found in, p its position in the chunk, prev the character
# before the chunk. It sets plaus to 1 when the candidate passed the cheap
# boundary and length checks, which is what counts toward the MAXM limit.
function check(t, m, s, p, prev,    v, tail, n, parts, i, ok, after, q, rest, lv, pfx) {
  plaus = 0
  if (t == "aws_key") {
    if (length(m) < 20) return
    plaus = 1
    v = substr(m, 1, 20)
    if (is_placeholder(v)) return
    record(t, "AWS access key ID", substr(m, 1, 4), 20)
  } else if (t == "aws_secret") {
    v = m; sub(/^[^:=]*[:=][ \t]*["']?/, "", v)
    if (length(v) != 40) return
    plaus = 1
    if (is_placeholder(v)) return
    record("aws_secret", "AWS secret access key", "", 40)
  } else if (t == "aws_secret_bare") {
    if (length(m) != 40 || !looks_random(m) || m ~ /=/) return
    if (!boundary_ok(s, p, prev)) return
    after = substr(s, p + length(m), 1)
    if (after ~ /[A-Za-z0-9\/+=]/) return
    plaus = 1
    if (is_placeholder(m)) return
    record("aws_secret", "AWS secret access key", "", 40)
  } else if (t == "github") {
    tail = m; sub(/^gh[pousr]_/, "", tail)
    if (length(tail) < 36 || !boundary_ok(s, p, prev)) return
    plaus = 1
    if (is_placeholder(tail)) return
    record(t, "GitHub token", substr(m, 1, 4), length(tail))
  } else if (t == "github_pat") {
    tail = substr(m, 12)
    if (length(tail) < 22 || !boundary_ok(s, p, prev)) return
    plaus = 1
    if (is_placeholder(tail)) return
    record("github", "GitHub token", "github_pat_", length(tail))
  } else if (t == "gitlab") {
    tail = substr(m, 7)
    if (length(tail) < 20 || !boundary_ok(s, p, prev)) return
    plaus = 1
    if (is_placeholder(tail)) return
    record(t, "GitLab personal access token", "glpat-", length(tail))
  } else if (t == "anthropic") {
    tail = substr(m, 8)
    if (length(tail) < 20 || !boundary_ok(s, p, prev)) return
    plaus = 1
    if (is_placeholder(tail)) return
    record(t, "Anthropic API key", "sk-ant-", length(tail))
  } else if (t == "openai") {
    if (m ~ /^sk-ant-/ || !boundary_ok(s, p, prev)) return
    if (m ~ /^sk-(proj|svcacct|admin)-/) {
      # Project, service account, and admin keys are long random strings
      # that may contain - and _. A slug made of short hyphenated words is
      # not a key, so at least one long random-looking segment is required.
      tail = m; sub(/^sk-(proj|svcacct|admin)-/, "", tail)
      pfx = substr(m, 1, length(m) - length(tail))
      if (length(tail) < 32 || !looks_random(tail)) return
      n = split(tail, parts, /[-_]/); ok = 0
      for (i = 1; i <= n; i++) if (length(parts[i]) >= 16) ok = 1
      if (!ok) return
    } else {
      # Legacy keys are sk- followed by letters and digits only.
      tail = substr(m, 4); pfx = "sk-"
      if (tail !~ /^[A-Za-z0-9]+$/ || length(tail) < 32 || !looks_random(tail)) return
    }
    plaus = 1
    if (is_placeholder(tail)) return
    record(t, "OpenAI API key", pfx, length(tail))
  } else if (t == "stripe") {
    tail = m; sub(/^(sk|rk)_(live|test)_/, "", tail)
    if (length(tail) < 10 || !boundary_ok(s, p, prev)) return
    plaus = 1
    if (is_placeholder(tail)) return
    record(t, "Stripe secret or restricted key", substr(m, 1, length(m) - length(tail)), length(tail))
  } else if (t == "stripe_whsec") {
    tail = substr(m, 7)
    if (length(tail) < 24 || !boundary_ok(s, p, prev)) return
    plaus = 1
    if (is_placeholder(tail)) return
    record(t, "Stripe webhook signing secret", "whsec_", length(tail))
  } else if (t == "slack") {
    tail = substr(m, 6)
    if (length(tail) < 10 || !boundary_ok(s, p, prev)) return
    plaus = 1
    if (is_placeholder(tail)) return
    record(t, "Slack token", substr(m, 1, 5), length(tail))
  } else if (t == "google") {
    tail = substr(m, 5)
    if (length(tail) < 35 || !boundary_ok(s, p, prev)) return
    plaus = 1
    if (is_placeholder(tail)) return
    record(t, "Google API key", "AIza", length(tail))
  } else if (t == "nvidia") {
    tail = substr(m, 7)
    if (length(tail) < 20 || !boundary_ok(s, p, prev)) return
    plaus = 1
    if (is_placeholder(tail)) return
    record(t, "NVIDIA API key", "nvapi-", length(tail))
  } else if (t == "huggingface") {
    tail = substr(m, 4)
    if (length(tail) < 30 || tail !~ /[A-Z]/ || tail !~ /[a-z]/) return
    if (!boundary_ok(s, p, prev)) return
    plaus = 1
    if (is_placeholder(tail)) return
    record(t, "Hugging Face token", "hf_", length(tail))
  } else if (t == "supabase") {
    tail = substr(m, 11)
    if (length(tail) < 20 || !boundary_ok(s, p, prev)) return
    plaus = 1
    if (is_placeholder(tail)) return
    record(t, "Supabase secret key", "sb_secret_", length(tail))
  } else if (t == "jwt") {
    n = split(m, parts, /\./)
    if (n != 3 || length(parts[1]) < 10 || length(parts[2]) < 10 || length(parts[3]) < 10) return
    if (!boundary_ok(s, p, prev)) return
    plaus = 1
    if (is_placeholder(parts[2] parts[3])) return
    record(t, "JWT (for example a Supabase key)", "eyJ", length(m))
  } else if (t == "db_url") {
    v = m; sub(/^[^:]*:\/\/[^:]*:/, "", v); sub(/@$/, "", v)
    lv = tolower(v)
    if (lv ~ /^(password|passwd|pass|pw|pwd|secret|postgres|root|admin|user|test|mysql|guest)$/) return
    # Very short values are still checked, but they do not count toward
    # the candidate limit, so a long list of user:x@ URLs cannot use it up.
    if (length(v) >= 6) plaus = 1
    if (is_placeholder(v)) return
    pfx = m; sub(/:\/\/.*$/, "://", pfx)
    record(t, "database URL with an inline password", pfx, length(v))
  } else if (t == "password" || t == "env_secret") {
    # m runs from the keyword through the separator and any spaces. The
    # value is read from what follows it in the chunk.
    rest = substr(s, p + length(m))
    if (substr(m, length(m), 1) == "=" && substr(rest, 1, 1) == "=") return
    # A keyword inside a shell expansion such as ${DB_PASSWORD:-admin} is
    # part of a variable name, and the default after it is code.
    if (in_expansion(s, p)) return
    q = substr(rest, 1, 1)
    if (q == "\"" || q == "'" || q == "`") {
      rest = substr(rest, 2)
      i = index(rest, q)
      if (i == 0) return
      v = substr(rest, 1, i - 1)
      if (v ~ /[ \t]/) return
    } else {
      if (match(rest, /^[^ \t"'`,;]+/) == 0) return
      v = clean(substr(rest, 1, RLENGTH))
      if (is_code_expr(v)) return
      # A bare identifier such as userPassword or String is a variable or a
      # type, so identifier-shaped values need to be long and contain digits.
      if (v ~ /^[A-Za-z_][A-Za-z0-9_]*$/ && (length(v) < 8 || v !~ /[0-9]/)) return
    }
    if (is_code_expr(v)) return
    if (length(v) < (t == "password" ? 6 : 16)) return
    plaus = 1
    if (is_placeholder(v)) return
    if (t == "password") {
      lv = tolower(v)
      if (lv ~ /^(true|false|null|none|nil|undefined|required|optional|string|str)$/) return
      # Plain words are usually prose ("password: forgotten"), so require
      # at least one character that is not a letter.
      if (v !~ /[^A-Za-z]/) return
      record(t, "password assignment", "", length(v))
    } else {
      # A generic SECRET/TOKEN/API_KEY assignment is only flagged when the
      # value is long and mixes character classes like a generated secret.
      if (v ~ /:\/\//) return
      if (v !~ /[0-9]/ || v !~ /[A-Za-z]/) {
        if (!(v ~ /[A-Z]/ && v ~ /[a-z]/ && length(v) >= 20)) return
      }
      # Lower case words joined by - . or / are slugs and paths.
      if (v ~ /^[a-z0-9._\/-]+$/ && v ~ /[._\/-]/) return
      record(t, "secret environment variable", "", length(v))
    }
  }
}

# Runs one rule over a chunk. re is the pattern; when icase is set the
# match runs against the lower-cased chunk ls and the text is taken from s.
# After every match the rest of the chunk is copied and searched again, and
# that copy is what costs time, so its length is added to work. Reaching
# MAXWORK, or MAXM plausible candidates for one rule, ends the scan and
# marks the prompt as too large to scan fully, which blocks it.
function scan(t, re, s, ls, icase, prev,    hay, off, pos, m) {
  if (toolarge || t in done) return
  hay = icase ? ls : s
  off = 0
  while (match(hay, re)) {
    pos = off + RSTART
    m = substr(s, pos, RLENGTH)
    check(t, m, s, pos, prev)
    if (t in done) return
    if (plaus && ++count[t] >= MAXM) { toolarge = 1; return }
    off += RSTART + RLENGTH - 1
    if (RLENGTH < 1) off++
    hay = substr(hay, RSTART + (RLENGTH > 0 ? RLENGTH : 1))
    work += length(hay) + 1
    if (work >= MAXWORK) { toolarge = 1; return }
  }
}

function scan_chunk(s, prev,    ls) {
  ls = tolower(s)
  if (index(s, "AKIA") || index(s, "ASIA")) {
    aws_ctx = NR_LINE
    scan("aws_key", "(AKIA|ASIA)[0-9A-Z]+", s, ls, 0, prev)
  }
  if (index(ls, "aws")) {
    scan("aws_secret", "aws_?secret(_access)?(_key)?[\"']?[ \t]*[:=][ \t]*[\"']?[a-z0-9/+=]+", s, ls, 1, prev)
    aws_ctx = NR_LINE
  }
  # Only runs of 40 or more key characters can be a bare AWS secret, so the
  # pattern spells out 40 characters instead of matching every word.
  if (aws_ctx && NR_LINE - aws_ctx <= 3) scan("aws_secret_bare", AWS40, s, ls, 0, prev)
  if (index(s, "gh")) scan("github", "gh[pousr]_[A-Za-z0-9]+", s, ls, 0, prev)
  if (index(s, "github_pat_")) scan("github_pat", "github_pat_[A-Za-z0-9_]+", s, ls, 0, prev)
  if (index(s, "glpat-")) scan("gitlab", "glpat-[A-Za-z0-9_-]+", s, ls, 0, prev)
  if (index(s, "sk-")) {
    scan("anthropic", "sk-ant-[A-Za-z0-9_-]+", s, ls, 0, prev)
    scan("openai", "sk-[A-Za-z0-9_-]+", s, ls, 0, prev)
  }
  if (index(s, "k_live_") || index(s, "k_test_")) scan("stripe", "(sk|rk)_(live|test)_[A-Za-z0-9]+", s, ls, 0, prev)
  if (index(s, "whsec_")) scan("stripe_whsec", "whsec_[A-Za-z0-9+/=]+", s, ls, 0, prev)
  if (index(s, "xox")) scan("slack", "xox[baprs]-[A-Za-z0-9-]+", s, ls, 0, prev)
  if (index(s, "AIza")) scan("google", "AIza[0-9A-Za-z_-]+", s, ls, 0, prev)
  if (index(s, "nvapi-")) scan("nvidia", "nvapi-[A-Za-z0-9_-]+", s, ls, 0, prev)
  if (index(s, "hf_")) scan("huggingface", "hf_[A-Za-z0-9]+", s, ls, 0, prev)
  if (index(s, "sb_secret_")) scan("supabase", "sb_secret_[A-Za-z0-9_-]+", s, ls, 0, prev)
  if (index(s, "eyJ")) scan("jwt", "eyJ[A-Za-z0-9_-]+\\.eyJ[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+", s, ls, 0, prev)
  if (index(s, "://")) scan("db_url", "[A-Za-z][A-Za-z0-9+.-]*://[^:/ \t@\"]+:[^@ \t\"/]+@", s, ls, 0, prev)
  if (index(ls, "passw")) scan("password", "passw(or)?d[\"'`]?[ \t]*(:=|[:=])[ \t]*", s, ls, 1, prev)
  if (s ~ /SECRET|TOKEN|API_?KEY|PRIVATE_KEY|SERVICE_ROLE|ACCESS_KEY/) \
    scan("env_secret", "(SECRET|TOKEN|API_KEY|APIKEY|PRIVATE_KEY|SERVICE_ROLE|ACCESS_KEY)[A-Z0-9_]*[\"']?[ \t]*=[ \t]*", s, ls, 0, prev)
}

# Scans one line of the prompt, in overlapping chunks when it is long.
function scan_line(line,    n, start, chunk, prev, hpos, rest) {
  NR_LINE++
  if (index(line, "#allow-secret")) allowed = 1
  if (toolarge) return
  # A private key header only counts when key material follows it, so that
  # questions about the PEM format are not blocked.
  if (!("private_key" in done)) {
    if (in_key) {
      if (line !~ /-----/ && line ~ /[A-Za-z0-9+\/=][A-Za-z0-9+\/=][A-Za-z0-9+\/=][A-Za-z0-9+\/=][A-Za-z0-9+\/=]/) {
        rest = line; gsub(/[^A-Za-z0-9+\/=]/, " ", rest)
        if (longest_run(rest) >= 40) record("private_key", "private key block", "", "unknown")
      }
    }
    if (index(line, "PRIVATE KEY-----") && match(line, /-----BEGIN [A-Z ]*PRIVATE KEY-----/)) {
      in_key = 1
      key_header = substr(line, RSTART, RLENGTH)
      rest = substr(line, RSTART + RLENGTH); gsub(/-----[A-Z ]+-----/, " ", rest)
      gsub(/[^A-Za-z0-9+\/=]/, " ", rest)
      if (longest_run(rest) >= 40) record("private_key", "private key block", "", "unknown")
    }
  }
  n = length(line)
  if (n <= CHUNK + OVERLAP) { scan_chunk(line, ""); return }
  for (start = 1; start <= n; start += CHUNK) {
    chunk = substr(line, start, CHUNK + OVERLAP)
    prev = (start > 1) ? substr(line, start - 1, 1) : ""
    scan_chunk(chunk, prev)
  }
}

function longest_run(s,    n, parts, i, best) {
  n = split(s, parts, / +/); best = 0
  for (i = 1; i <= n; i++) if (length(parts[i]) > best) best = length(parts[i])
  return best
}

# Without jq the hook input is raw JSON. This extracts and decodes the
# prompt string. Unicode escapes are left as they are, which the patterns
# tolerate. If the prompt key cannot be found, the whole input is scanned.
function decode_prompt(doc,    i, rest, j) {
  gsub(/\\\\/, "\001", doc)
  gsub(/\\"/, "\002", doc)
  if (match(doc, /"prompt"[ \t\r\n]*:[ \t\r\n]*"/)) {
    rest = substr(doc, RSTART + RLENGTH)
    j = index(rest, "\"")
    if (j > 0) doc = substr(rest, 1, j - 1)
    else doc = rest
  }
  gsub(/\\n/, "\n", doc)
  gsub(/\\r/, "", doc)
  gsub(/\\t/, "\t", doc)
  gsub(/\\\//, "/", doc)
  gsub(/\002/, "\"", doc)
  gsub(/\001/, "\\", doc)
  return doc
}

BEGIN {
  MAXM = 5000; MAXWORK = 1000000000; CHUNK = 4096; OVERLAP = 512
  found = ""; first_mask = ""; allowed = 0; NR_LINE = 0; aws_ctx = 0; in_key = 0
  toolarge = 0; work = 0
  AWS40 = ""
  for (k = 0; k < 40; k++) AWS40 = AWS40 "[A-Za-z0-9/+=]"
  AWS40 = AWS40 "*"
}

mode == "json" { raw = (NR == 1) ? $0 : raw "\n" $0; next }
{ scan_line($0) }

END {
  if (mode == "json") {
    text = decode_prompt(raw)
    n = split(text, lines, "\n")
    for (k = 1; k <= n; k++) scan_line(lines[k])
  }
  if (allowed) exit
  if (found != "") printf "%s\t%s\n", found, first_mask
  else if (toolarge) printf "@toolarge\t\n"
}
AWK

if have_jq; then
  result=$(printf '%s' "$input" | jq -r '.prompt // empty' 2>/dev/null |
    LC_ALL=C awk -v mode=text "$SCANNER")
else
  result=$(printf '%s\n' "$input" | LC_ALL=C awk -v mode=json "$SCANNER")
fi

[ -z "$result" ] && exit 0
found_types=${result%%$'\t'*}
first_mask=${result#*$'\t'}

if [ "$found_types" = "@toolarge" ]; then
  reason="Blocked: prompt too large to scan fully for secrets; add #allow-secret if it contains none. It was not sent to Claude. The scan stopped early because the prompt has an unusually large number of credential-like candidates, and the hook does not let a prompt through unscanned."
else
  reason="Blocked: this prompt appears to contain a credential ($found_types; $first_mask). It was not sent to Claude. If the credential is real, rotate it now, because it may already be in your terminal scrollback, in Claude Code's local prompt history, or in your shell history. Keep secrets in environment variables or your shell profile and refer to them by name instead of pasting them. If this is a false positive, resend the prompt with #allow-secret anywhere in it."
fi

printf '{"decision": "block", "reason": %s, "hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "suppressOriginalPrompt": true}}\n' \
  "$(json_str "$reason")"
exit 0
