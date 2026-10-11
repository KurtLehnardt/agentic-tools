#!/usr/bin/env bash
# Stop hook: warns the user about unsaved git work when Claude finishes a turn.
#
# It reports uncommitted changes (staged, unstaged, and untracked files that
# are not ignored), commits that have not been pushed to the upstream, and a
# current branch that has no upstream at all. It also looks at the other
# worktrees of the same repository and summarizes up to five of them.
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
MAX_SCANNED_WORKTREES=20

# Prints a one-line summary of unsaved work in the worktree at $1, or
# nothing when the worktree is clean and fully pushed. When $2 is "current",
# a branch without an upstream is always reported. For other worktrees it
# is only reported when that branch has commits that exist on no remote.
summarize_worktree() {
  local path=$1 mode=$2
  local counts staged unstaged untracked
  counts=$(git -C "$path" status --porcelain=v1 2>/dev/null | awk '
    { x = substr($0, 1, 1); y = substr($0, 2, 1)
      if (x == "?" && y == "?") u++
      else { if (x != " ") s++; if (y != " ") m++ } }
    END { print s + 0, m + 0, u + 0 }') || return 0
  read -r staged unstaged untracked <<EOF
$counts
EOF
  staged=${staged:-0}
  unstaged=${unstaged:-0}
  untracked=${untracked:-0}

  local parts=""
  [ "$staged" -gt 0 ] && parts="$parts, $staged staged"
  [ "$unstaged" -gt 0 ] && parts="$parts, $unstaged unstaged"
  [ "$untracked" -gt 0 ] && parts="$parts, $untracked untracked"
  [ -n "$parts" ] && parts="uncommitted changes (${parts#, })"

  local branch upstream ahead push_note=""
  branch=$(git -C "$path" symbolic-ref --quiet --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    upstream=$(git -C "$path" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)
    if [ -n "$upstream" ]; then
      ahead=$(git -C "$path" rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)
      [ "${ahead:-0}" -gt 0 ] && push_note="$ahead commit(s) not pushed to $upstream"
    else
      local local_only
      local_only=$(git -C "$path" rev-list --count HEAD --not --remotes 2>/dev/null || echo 0)
      if [ "$mode" = "current" ] || [ "${local_only:-0}" -gt 0 ]; then
        push_note="no upstream branch ($local_only commit(s) not on any remote)"
      fi
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
current_summary=$(summarize_worktree "$current_top" current)
[ -n "$current_summary" ] && message="Unsaved git work in $current_summary"

# Collect the other worktrees of this repository. Bare and missing
# worktrees are skipped.
others=""
other_count=0
scanned=0
while IFS= read -r wt; do
  [ -z "$wt" ] && continue
  [ -d "$wt" ] || continue
  wt_real=$(cd "$wt" 2>/dev/null && pwd -P) || continue
  [ "$wt_real" = "$current_real" ] && continue
  [ "$(git -C "$wt" rev-parse --is-bare-repository 2>/dev/null)" = "true" ] && continue
  scanned=$((scanned + 1))
  [ "$scanned" -gt "$MAX_SCANNED_WORKTREES" ] && break
  line=$(summarize_worktree "$wt" other)
  [ -z "$line" ] && continue
  other_count=$((other_count + 1))
  if [ "$other_count" -le "$MAX_REPORTED_WORKTREES" ]; then
    others="$others
  - $line"
  fi
done <<EOF
$(git worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p')
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
