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
#
# Only fenced blocks tagged bash, sh, shell, zsh, console, powershell, pwsh,
# ps1, cmd, or untagged are treated as commands. A leading "$ " or "> " prompt
# is stripped and lines ending in "\" are joined. Commented lines are skipped.
# The flags are heuristics for the agent to confirm, not verdicts.
set -euo pipefail

README="${1:-README.md}"
[ -f "$README" ] || { echo "extract-readme-steps: no such file: $README" >&2; exit 2; }

awk '
BEGIN {
  FS = "\n"; n = 0; infence = 0; cmdfence = 0; section = "(top)"; prose = ""; pending = ""
  split("bash sh shell zsh console powershell pwsh ps1 cmd", L, " ")
  for (i in L) ok[L[i]] = 1
  split("cd export echo cp mv mkdir source cat ls rm set unset sudo chmod chown touch if then fi for do done while true false test exit printf eval exec env read wait cls dir copy del", B, " ")
  for (i in B) builtin[B[i]] = 1
}
/^[ \t]*```/ {
  if (!infence) {
    infence = 1
    lang = $0; sub(/^[ \t]*```+[ \t]*/, "", lang); sub(/[ \t{].*$/, "", lang); lang = tolower(lang)
    cmdfence = (lang == "" || (lang in ok))
  } else { infence = 0; cmdfence = 0; pending = "" }
  next
}
!infence && /^#+[ \t]/ { section = $0; sub(/^#+[ \t]+/, "", section) }
!infence { prose = prose " " tolower($0); next }
cmdfence {
  line = $0
  sub(/^[ \t]+/, "", line)
  if (line == "" || line ~ /^#/ || line ~ /^(REM|::) /) next
  sub(/^(\$|>|PS>|PS [^>]*>)[ \t]+/, "", line)
  if (line ~ /\\$/) { sub(/\\$/, "", line); pending = pending line " "; next }
  line = pending line; pending = ""
  n++
  printf "STEP\t%d\t%s\t%s\t%s\n", n, section, (lang == "" ? "-" : lang), line
  cmds[n] = line
}
END {
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
      if (w == "" || w ~ /^[.\/~$(]/ || w ~ /=/ || (w in builtin) || (w in seent)) continue
      seent[w] = 1
      alias = (w ~ /^(npm|npx)$/) ? "node" : (w ~ /^pip3?$/) ? "python" : (w == "corepack") ? "node" : w
      if (index(prose, tolower(w)) == 0 && index(prose, alias) == 0) printf "FLAG\tUNSTATED_PREREQ\t%s\n", w
    }
    if (c ~ /(^|[ \t])(read|passwd|ssh-keygen|gh auth login|aws configure|npx create-|npm init)([ \t]|$)/ && c !~ /(-y|--yes|--non-interactive)/)
      printf "FLAG\tINTERACTIVE\t%d\n", k
    if (c ~ /<[a-zA-Z_ -]+>|YOUR_[A-Z_]+|your-[a-z-]+/) printf "FLAG\tPLACEHOLDER\t%d\n", k
  }
}' "$README"
