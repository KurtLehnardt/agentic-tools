#!/usr/bin/env bash
# SessionStart hook: tells Claude and the user when the current branch is
# behind its upstream or behind the remote default branch.
#
# It runs a short, time-limited git fetch and then compares HEAD with its
# upstream and with origin/<default branch>. When HEAD is behind, it adds
# context asking Claude to pull or rebase before starting work, and shows a
# short message to the user.
#
# This hook never pulls, merges, or rebases anything, because that could
# overwrite work in progress. It stays silent when the branch is up to date,
# when there is no remote, and when the fetch fails or times out.

set -u

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source-path=SCRIPTDIR source=lib.sh
. "$script_dir/lib.sh"

hook_disabled session-behind-main && exit 0
command -v git >/dev/null 2>&1 || exit 0

input=$(cat)
cwd=$(json_get "$input" cwd)
if [ -n "$cwd" ] && [ -d "$cwd" ]; then cd "$cwd" 2>/dev/null || exit 0; fi
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

FETCH_TIMEOUT=${AGENTIC_HOOKS_FETCH_TIMEOUT:-5}

# Never let the fetch prompt for credentials, since nobody can answer.
export GIT_TERMINAL_PROMPT=0
export GIT_OPTIONAL_LOCKS=0
# Keep the user's own ssh command (GIT_SSH_COMMAND, or core.sshCommand from
# git config), and only append options that stop ssh from prompting or
# waiting on a slow connection. Options given on the command line apply
# alongside the user's ~/.ssh/config, so host aliases and keys still work.
base_ssh=${GIT_SSH_COMMAND:-$(git config --get core.sshCommand 2>/dev/null || echo ssh)}
[ -z "$base_ssh" ] && base_ssh=ssh
export GIT_SSH_COMMAND="$base_ssh -o BatchMode=yes -o ConnectTimeout=$FETCH_TIMEOUT"

branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null)
upstream=""
upstream_remote=""
if [ -n "$branch" ]; then
  upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)
  upstream_remote=$(git config --get "branch.$branch.remote" 2>/dev/null)
fi

has_origin=0
git remote get-url origin >/dev/null 2>&1 && has_origin=1

# Nothing to compare against without a remote.
[ "$has_origin" -eq 0 ] && [ -z "$upstream" ] && exit 0

# Fetch origin, plus the upstream remote when it is a different one. Any
# failure is treated as being offline, and the hook exits silently.
remotes=""
[ "$has_origin" -eq 1 ] && remotes="origin"
if [ -n "$upstream_remote" ] && [ "$upstream_remote" != "." ] && [ "$upstream_remote" != "origin" ]; then
  remotes="$remotes $upstream_remote"
fi
for remote in $remotes; do
  run_with_timeout "$FETCH_TIMEOUT" git fetch --quiet --no-tags "$remote" >/dev/null 2>&1 || exit 0
done

# Work out the remote default branch from origin/HEAD, falling back to
# main and then master.
default_ref=""
if [ "$has_origin" -eq 1 ]; then
  default_ref=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)
  if [ -z "$default_ref" ]; then
    for candidate in main master; do
      if git rev-parse --verify --quiet "refs/remotes/origin/$candidate" >/dev/null; then
        default_ref="origin/$candidate"
        break
      fi
    done
  fi
fi

notes=""
behind_upstream=0
if [ -n "$upstream" ]; then
  behind_upstream=$(git rev-list --count "HEAD..@{u}" 2>/dev/null || echo 0)
  if [ "${behind_upstream:-0}" -gt 0 ]; then
    notes="$behind_upstream commit(s) behind its upstream $upstream"
  fi
fi

if [ -n "$default_ref" ] && [ "$default_ref" != "$upstream" ]; then
  behind_default=$(git rev-list --count "HEAD..$default_ref" 2>/dev/null || echo 0)
  if [ "${behind_default:-0}" -gt 0 ]; then
    [ -n "$notes" ] && notes="$notes and "
    notes="${notes}${behind_default} commit(s) behind $default_ref"
  fi
fi

[ -z "$notes" ] && exit 0

label=${branch:-"detached HEAD"}
context="Git status at session start: the current branch ($label) is $notes. Before starting new work, tell the user and ask whether to pull or rebase (for example git pull --rebase, or git rebase ${default_ref:-$upstream}). Do not pull, merge, or rebase without the user's agreement if there are uncommitted changes. This hook did not change anything."
user_msg="Branch $label is $notes. Consider pulling or rebasing before you start. Nothing was pulled automatically."

printf '{"systemMessage": %s, "hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": %s}}\n' \
  "$(json_str "$user_msg")" "$(json_str "$context")"
exit 0
