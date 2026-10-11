#!/usr/bin/env bash
# Stop hook: warns the user about unsaved git work when Claude finishes a turn.
#
# It reports uncommitted changes (staged, unstaged, and untracked files that
# are not ignored), commits that have not been pushed to the upstream, and a
# branch with no upstream whose commits exist on no remote. It stays silent
# about push status when the repository has no remote. On a branch with no
# commits yet (a fresh git init), it still reports uncommitted files but
# skips the push status, since there is nothing to push. It also looks at
# up to ten other worktrees of the same repository, skipping agent worktrees
# under .claude/worktrees/, and summarizes up to five of them.
#
# This hook only warns. It never blocks the stop, never asks Claude to keep
# working, never touches the network, and always exits 0.

set -u

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source-path=SCRIPTDIR source=lib.sh
. "$script_dir/lib.sh"

hook_disabled stop-unsaved-work && exit 0
command -v git >/dev/null 2>&1 || exit 0

input=$(cat)

# If a Stop hook already made Claude continue, stay quiet to avoid loops.
[ "$(json_get "$input" stop_hook_active)" = "true" ] && exit 0

cwd=$(json_get "$input" cwd)
if [ -n "$cwd" ] && [ -d "$cwd" ]; then cd "$cwd" 2>/dev/null || exit 0; fi
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# Avoid taking the index lock, so this hook never races with another git
# process that Claude or the user is running at the same time.
export GIT_OPTIONAL_LOCKS=0

MAX_REPORTED_WORKTREES=5
# Each sibling worktree costs one or two git processes, so the scan stops
# after this many to keep the hook well under a second.
MAX_SCANNED_WORKTREES=10

# Without a remote nothing can be pushed, so push status is not reported.
has_remote=0
[ -n "$(git remote 2>/dev/null)" ] && has_remote=1

# Prints a one-line summary of unsaved work in the worktree at $1, or
# nothing when the worktree is clean and fully pushed. A single
# "git status --porcelain=v2 --branch" call supplies the file counts, the
# branch, its upstream, and the ahead count. On a branch with no commits yet
# only the file counts are reported. A branch without an upstream is only
# reported when the repository has a remote and the branch has commits that
# exist on no remote.
summarize_worktree() {
  local path=$1
  local status fields oid branch upstream ahead staged unstaged untracked unborn=0
  status=$(git -C "$path" status --porcelain=v2 --branch 2>/dev/null) || return 0
  fields=$(printf '%s\n' "$status" | awk '
    $1 == "#" && $2 == "branch.oid" { oid = $3 }
    $1 == "#" && $2 == "branch.head" { head = $3 }
    $1 == "#" && $2 == "branch.upstream" { up = $3 }
    $1 == "#" && $2 == "branch.ab" { ahead = substr($3, 2) }
    $1 == "1" || $1 == "2" {
      x = substr($2, 1, 1); y = substr($2, 2, 1)
      if (x != ".") s++
      if (y != ".") m++
    }
    $1 == "u" { m++ }
    $1 == "?" { u++ }
    END {
      printf "%s %s %s %s %d %d %d\n", (oid == "" ? "-" : oid), (head == "" ? "-" : head),
        (up == "" ? "-" : up), (ahead == "" ? 0 : ahead), s, m, u
    }')
  read -r oid branch upstream ahead staged unstaged untracked <<EOF
$fields
EOF
  # An unborn branch has no commits, so there is nothing to push, but its
  # uncommitted files are still reported.
  [ "$oid" = "(initial)" ] && unborn=1
  case "$branch" in "(detached)" | "-") branch="" ;; esac
  [ "$upstream" = "-" ] && upstream=""

  local parts=""
  [ "${staged:-0}" -gt 0 ] && parts="$parts, $staged staged"
  [ "${unstaged:-0}" -gt 0 ] && parts="$parts, $unstaged unstaged"
  [ "${untracked:-0}" -gt 0 ] && parts="$parts, $untracked untracked"
  [ -n "$parts" ] && parts="uncommitted changes (${parts#, })"

  local push_note="" local_only
  if [ "$unborn" -eq 0 ] && [ -n "$branch" ] && [ "$has_remote" -eq 1 ]; then
    if [ -n "$upstream" ]; then
      [ "${ahead:-0}" -gt 0 ] && push_note="$ahead commit(s) not pushed to $upstream"
    else
      local_only=$(git -C "$path" rev-list --count HEAD --not --remotes 2>/dev/null)
      [ "${local_only:-0}" -gt 0 ] &&
        push_note="no upstream branch ($local_only commit(s) not on any remote)"
    fi
  fi

  [ -z "$parts" ] && [ -z "$push_note" ] && return 0
  local summary=$parts
  if [ -n "$push_note" ]; then
    if [ -n "$summary" ]; then summary="$summary; $push_note"; else summary=$push_note; fi
  fi
  printf '%s (%s): %s\n' "$path" "${branch:-detached HEAD}" "$summary"
}

current_top=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
current_real=$(cd "$current_top" && pwd -P)

message=""
current_summary=$(summarize_worktree "$current_top")
[ -n "$current_summary" ] && message="Unsaved git work in $current_summary"

# Collect the other worktrees of this repository. Bare and missing
# worktrees are skipped, and so are agent worktrees under .claude/worktrees/,
# which Claude Code creates and cleans up on its own.
others=""
other_count=0
scanned=0
while IFS= read -r wt; do
  [ -z "$wt" ] && continue
  case "$wt" in */.claude/worktrees/*) continue ;; esac
  [ -d "$wt" ] || continue
  wt_real=$(cd "$wt" 2>/dev/null && pwd -P) || continue
  [ "$wt_real" = "$current_real" ] && continue
  scanned=$((scanned + 1))
  [ "$scanned" -gt "$MAX_SCANNED_WORKTREES" ] && break
  line=$(summarize_worktree "$wt")
  [ -z "$line" ] && continue
  other_count=$((other_count + 1))
  if [ "$other_count" -le "$MAX_REPORTED_WORKTREES" ]; then
    others="$others
  - $line"
  fi
done <<EOF
$(git worktree list --porcelain 2>/dev/null | awk '
  /^worktree / { if (path != "" && !bare) print path; path = substr($0, 10); bare = 0; next }
  /^bare$/ { bare = 1 }
  END { if (path != "" && !bare) print path }')
EOF

if [ "$other_count" -gt 0 ]; then
  [ "$other_count" -gt "$MAX_REPORTED_WORKTREES" ] &&
    others="$others
  - and $((other_count - MAX_REPORTED_WORKTREES)) more worktree(s)"
  if [ -n "$message" ]; then message="$message
"; fi
  message="${message}Other worktrees of this repo with unsaved work:$others"
fi

[ -z "$message" ] && exit 0

printf '{"systemMessage": %s}\n' "$(json_str "$message")"
exit 0
