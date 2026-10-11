#!/usr/bin/env bash
# extract-readme-steps.sh: list a README's install commands literally, in order,
# and flag assumptions the README never states.
#
# Usage:
#   extract-readme-steps.sh [README.md]
#
# Output (tab-separated, stdout):
#   STEP  <n>  <section heading>  <fence language>  <command exactly as written>
#   FLAG  UNDOCUMENTED_ENV  <VAR>   variable used in a command, never named in prose
#   FLAG  UNSTATED_PREREQ   <tool>  tool a command calls, never named in prose
#   FLAG  INTERACTIVE       <n>     step likely to prompt for input
#   FLAG  PLACEHOLDER       <n>     step contains <angle> or YOUR_ placeholder text
#   FLAG  SKIPPED_FENCE     <line>  untagged fence that looked like output or a
#                                   file tree; the agent should confirm the skip
#
# A multi-line command stays one STEP. That covers heredocs (from the line with
# <<WORD through the closing WORD line) and continued lines (a trailing "\" in
# shell, a trailing backtick in PowerShell, a trailing "^" in cmd). The command
# field is escaped so each STEP stays on one line: a backslash is written as
# "\\", a newline as "\n", and a tab as "\t". Decode it with printf '%b' before
# passing it to remote-exec.sh.
#
# Fence selection:
#   - Fences tagged bash, sh, shell, zsh, console, powershell, pwsh, ps1, or cmd
#     are commands. Fences with any other tag (json, python, yaml, and so on)
#     are skipped.
#   - Untagged fences are commands only when they look like commands: no line
#     starts with a tree-drawing character, and the first non-blank line starts
#     with a prompt, a relative or multi-segment absolute path (so a slash
#     command such as /status is not mistaken for one), a VAR=value
#     assignment, or a known command name.
#     Otherwise they are skipped and reported with FLAG SKIPPED_FENCE.
#   - In console blocks only lines that start with a "$ " or "> " prompt are
#     commands; the prompt is stripped and other lines are treated as output.
#     Elsewhere a leading prompt is stripped when present.
#   - Blank lines and comment lines outside heredocs are skipped.
#   - A "<<" inside a comment does not start a heredoc.
# The flags are heuristics for the agent to confirm, not verdicts.
set -euo pipefail

README="${1:-README.md}"
[ -f "$README" ] || { echo "extract-readme-steps: no such file: $README" >&2; exit 2; }

awk '
function esc(s) { gsub(/\\/, "\\\\", s); gsub(/\t/, "\\t", s); gsub(/\n/, "\\n", s); return s }

# strip_comment(line) -> the line without a trailing shell comment. A "#"
# starts a comment only at the start of a word and outside quotes.
function strip_comment(line,   i, c, q, prev) {
  q = ""; prev = " "
  for (i = 1; i <= length(line); i++) {
    c = substr(line, i, 1)
    if (q != "") { if (c == q) q = ""; else if (c == "\\" && q == "\"") i++ }
    else if (c == "\\") i++
    else if (c == "\047" || c == "\"") q = c
    else if (c == "#" && prev ~ /[ \t;&|(]/) return substr(line, 1, i - 1)
    prev = c
  }
  return line
}

# heredoc_word(line) -> delimiter of the first heredoc on the line, or "".
# Sets HD_STRIP to 1 for <<- (leading tabs allowed before the delimiter).
# A "<<" inside a comment does not start a heredoc.
function heredoc_word(line,   i, rest, w) {
  HD_STRIP = 0
  line = strip_comment(line)
  while ((i = index(line, "<<")) > 0) {
    rest = substr(line, i + 2)
    if (substr(rest, 1, 1) == "<") { line = substr(rest, 2); continue }
    if (substr(rest, 1, 1) == "-") { HD_STRIP = 1; rest = substr(rest, 2) }
    sub(/^[ \t]*/, "", rest)
    if (match(rest, /^["\047]?[A-Za-z_][A-Za-z0-9_]*["\047]?/)) {
      w = substr(rest, RSTART, RLENGTH); gsub(/["\047]/, "", w); return w
    }
    line = rest
  }
  return ""
}

function continued(line) {
  if (flang ~ /^(powershell|pwsh|ps1)$/) return line ~ /`$/
  if (flang == "cmd") return line ~ /\^$/
  return line ~ /\\$/
}

function emit() {
  if (buf == "") return
  n++
  printf "STEP\t%d\t%s\t%s\t%s\n", n, fsection, (flang == "" ? "-" : flang), esc(buf)
  cmds[n] = head
  buf = ""; head = ""
}

function looks_like_commands(   i, l, w) {
  for (i = 1; i <= nf; i++) if (fl[i] ~ /^[ \t]*(├|│|└)/) return 0
  for (i = 1; i <= nf; i++) {
    l = fl[i]; sub(/^[ \t]+/, "", l)
    if (l == "") continue
    if (l ~ /^(\$|>|PS>)[ \t]/ || l ~ /^(\.\.?\/|~\/|\/[^ \t\/]+\/)/ || l ~ /^[A-Za-z_][A-Za-z0-9_]*=/) return 1
    w = l; sub(/[ \t].*$/, "", w)
    return (w in known)
  }
  return 0
}

function process_fence(   i, raw, line, w) {
  buf = ""; head = ""; hd = ""
  for (i = 1; i <= nf; i++) {
    raw = fl[i]
    if (hd != "") {                       # inside a heredoc body: keep verbatim
      buf = buf "\n" raw
      line = raw; if (hdstrip) sub(/^\t+/, "", line)
      if (line == hd) { hd = ""; if (!cont) emit() }
      continue
    }
    if (buf != "") {                      # continuation of the previous line
      buf = buf "\n" raw
      line = raw; sub(/^[ \t]+/, "", line)
      head = head " " line
    } else {
      line = raw; sub(/^[ \t]+/, "", line)
      if (line == "" || line ~ /^#/ || line ~ /^(REM|rem|::)([ \t]|$)/) continue
      if (flang == "console") {
        if (line !~ /^(\$|>)[ \t]/) continue          # output, not a command
        sub(/^(\$|>)[ \t]+/, "", line)
      } else {
        sub(/^(\$|>|PS>|PS [^>]*>)[ \t]+/, "", line)
      }
      buf = line; head = line
    }
    w = heredoc_word(line)
    if (w != "") { hd = w; hdstrip = HD_STRIP }
    cont = continued(line)
    if (cont) sub(/[\\`^]$/, "", head)
    if (!cont && hd == "") emit()
  }
  emit()
}

function close_fence() {
  if (cmdfence || (flang == "" && looks_like_commands())) process_fence()
  else if (flang == "") printf "FLAG\tSKIPPED_FENCE\t%d\n", fstart
  nf = 0; infence = 0
}

BEGIN {
  n = 0; infence = 0; section = "(top)"; prose = ""; nf = 0
  split("bash sh shell zsh console powershell pwsh ps1 cmd", L, " ")
  for (i in L) ok[L[i]] = 1
  split("cd export echo cp mv mkdir source cat ls rm set unset sudo chmod chown touch if then fi for do done while true false test exit printf eval exec env read wait cls dir copy del", B, " ")
  for (i in B) builtin[B[i]] = 1
  split("git cd npm npx pnpm yarn bun bunx node deno corepack nvm fnm volta pip pip3 pipx python python3 py uv uvx poetry conda cargo rustup go make cmake brew apt apt-get dnf yum pacman zypper apk snap flatpak sudo curl wget docker podman kubectl helm terraform export source set cp mv mkdir cat echo chmod ln tar unzip gem bundle ruby mvn gradle java dotnet php composer ollama gh aws gcloud az choco winget scoop iwr irm Invoke-WebRequest Set-ExecutionPolicy sh bash zsh claude just task", K, " ")
  for (i in K) known[K[i]] = 1
}
/^[ \t]*```/ {
  if (!infence) {
    infence = 1; fstart = NR; fsection = section; nf = 0
    flang = $0; sub(/^[ \t]*```+[ \t]*/, "", flang); sub(/[ \t{,].*$/, "", flang); flang = tolower(flang)
    cmdfence = (flang in ok)
  } else close_fence()
  next
}
infence { fl[++nf] = $0; next }
/^#+[ \t]/ { section = $0; sub(/^#+[ \t]+/, "", section) }
{ prose = prose " " tolower($0) }
END {
  if (infence) close_fence()
  for (k = 1; k <= n; k++) {
    c = cmds[k]
    # environment variables: $VAR, ${VAR}, %VAR%, $env:VAR
    s = c
    while (match(s, /\$\{?[A-Z][A-Z0-9_]+\}?|%[A-Z][A-Z0-9_]+%|\$env:[A-Za-z_][A-Za-z0-9_]*/)) {
      v = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
      gsub(/[${}%]/, "", v); sub(/^env:/, "", v)
      if (v ~ /^(HOME|PATH|USER|PWD|SHELL|TMPDIR|USERPROFILE|APPDATA|LOCALAPPDATA)$/) continue
      if (!(v in seenv) && index(prose, tolower(v)) == 0) { seenv[v] = 1; printf "FLAG\tUNDOCUMENTED_ENV\t%s\n", v }
    }
    # first word of each command segment, including after && || ; |
    t = c; gsub(/&&|\|\||;|\|/, "\n", t)
    m = split(t, segs, "\n")
    for (j = 1; j <= m; j++) {
      w = segs[j]; sub(/^[ \t]+/, "", w); sub(/^sudo[ \t]+/, "", w); sub(/[ \t].*$/, "", w)
      if (w == "" || w ~ /^[.\/~$(<>]/ || w ~ /=/ || (w in builtin) || (w in seent)) continue
      seent[w] = 1
      alias = (w ~ /^(npm|npx)$/) ? "node" : (w ~ /^pip3?$/) ? "python" : (w == "corepack") ? "node" : w
      if (index(prose, tolower(w)) == 0 && index(prose, alias) == 0) printf "FLAG\tUNSTATED_PREREQ\t%s\n", w
    }
    if (c ~ /(^|[ \t])(read|passwd|ssh-keygen|gh auth login|aws configure|npx create-|npm init)([ \t]|$)/ && c !~ /(-y|--yes|--non-interactive)/)
      printf "FLAG\tINTERACTIVE\t%d\n", k
    if (c ~ /<[a-zA-Z_ -]+>|YOUR_[A-Z_]+|your-[a-z-]+/) printf "FLAG\tPLACEHOLDER\t%d\n", k
  }
}' "$README"
