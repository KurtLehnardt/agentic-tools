# agentic-tools hooks

This directory holds the Claude Code hooks that ship with the agentic-tools plugin. Claude Code loads `hooks/hooks.json` automatically from the plugin root, so no entry in `.claude-plugin/plugin.json` is needed. Each hook runs a bash script from `hooks/scripts/`, referenced through `${CLAUDE_PLUGIN_ROOT}`.

The scripts need only bash (3.2 or later, so the macOS system bash works) and git. They use `jq` when it is installed and fall back to a small built-in JSON parser when it is not.

| Hook event | Script | Purpose |
| --- | --- | --- |
| `Stop` | `scripts/stop-unsaved-work.sh` | Warns about uncommitted or unpushed work |
| `SessionStart` (`startup` and `resume`) | `scripts/session-behind-main.sh` | Warns when the branch is behind its upstream or the default branch |
| `UserPromptSubmit` | `scripts/secret-guard.sh` | Blocks prompts that contain credentials |

## Stop: unsaved-work warning

When Claude finishes a turn and the working directory is inside a git repository, this hook checks the current worktree for:

- uncommitted changes, counted separately as staged, unstaged, and untracked files (ignored files are not counted),
- commits that have not been pushed to the branch's upstream,
- a current branch that has no upstream, together with the number of its commits that exist on no remote.

It also runs `git worktree list` and checks the other worktrees of the same repository. Up to five worktrees with unsaved work are listed, and any beyond that are summarized as a count. For other worktrees, a branch without an upstream is only reported when it has commits that exist on no remote.

The result is shown to the user as a `systemMessage`.

What it does not do:

- It never blocks the stop and never asks Claude to keep working. It always exits 0.
- It does not use the network. It compares against the remote-tracking refs that are already on disk, so "not pushed" means "not pushed as of the last fetch".
- It stays silent when `stop_hook_active` is true, so it cannot take part in a stop loop.
- It does not take the git index lock (`GIT_OPTIONAL_LOCKS=0`), so it does not interfere with other git commands running at the same time.

Because `Stop` fires at the end of every turn, the warning repeats on each turn while the work stays unsaved. That is intentional, since the goal is to make unsaved work hard to forget.

## SessionStart: behind-main check

When a session starts or resumes inside a git repository, this hook:

1. Runs `git fetch --quiet --no-tags` for `origin` and, if different, for the upstream remote of the current branch. Each fetch is limited to 5 seconds. The limit uses `timeout` or `gtimeout` when one is installed, and otherwise a background watcher that stops the fetch. Credential prompts are disabled so the fetch can never hang waiting for input.
2. Compares `HEAD` with its upstream, and with `origin/<default branch>`. The default branch comes from `git symbolic-ref refs/remotes/origin/HEAD`, falling back to `origin/main` and then `origin/master`.
3. If `HEAD` is behind either one, it adds `additionalContext` telling Claude how many commits the branch is behind and asking it to raise a pull or rebase with the user before starting work. It also shows the user a short `systemMessage`.

What it does not do:

- It never pulls, merges, or rebases. Doing that automatically could overwrite work in progress.
- It prints nothing when the branch is up to date, when the repository has no remote, or when the fetch fails or times out (for example when offline).
- It does not run on `clear`, `compact`, or `fork` session starts.

The fetch limit can be changed with the `AGENTIC_HOOKS_FETCH_TIMEOUT` environment variable, in seconds.

## UserPromptSubmit: secret blocker

Before a prompt reaches Claude, this hook scans its text for likely credentials. When it finds one, it blocks the prompt with `decision: "block"` and a reason that names the type of credential. The reason tells the user to rotate the credential if it is real and to keep secrets in environment variables or the shell profile instead of pasting them.

Detected types:

- AWS access key IDs (`AKIA...` and `ASIA...`), and AWS secret access keys that follow an `aws_secret...` name
- GitHub tokens (`ghp_`, `gho_`, `ghu_`, `ghs_`, `ghr_`, and `github_pat_`)
- Anthropic API keys (`sk-ant-`)
- OpenAI API keys (`sk-` and `sk-proj-`)
- Stripe secret and restricted keys (`sk_live_`, `sk_test_`, `rk_live_`, `rk_test_`)
- Slack tokens (`xoxb-`, `xoxa-`, `xoxp-`, `xoxr-`, `xoxs-`)
- Google API keys (`AIza...`)
- NVIDIA API keys (`nvapi-`)
- Private key blocks (`-----BEGIN ... PRIVATE KEY-----` followed by key material)
- JWTs, which include Supabase anon and service role keys
- Database and other URLs with an inline password (`scheme://user:password@host`)
- Password assignments (`password: ...` or `password=...`)

The reason never repeats the secret. It shows only the first four characters of the match, which is the well-known prefix or keyword such as `ghp_` or `post`, and the length of the secret value.

To keep false positives low, the hook ignores:

- documentation examples and placeholders, such as values containing `EXAMPLE`, `your`, `xxxx`, `placeholder`, `changeme`, `<...>`, or `...`, and values made of very few distinct characters,
- environment variable references such as `${DB_PASSWORD}` or `os.environ[...]`,
- common local defaults such as `postgres://postgres:postgres@localhost`,
- `sk-` strings that do not look random, such as URL slugs,
- password values that are plain words, which are usually prose,
- a private key header with no key material after it, such as a question about the PEM format.

Escape hatch: a prompt that contains the literal text `#allow-secret` is always allowed. Use it for a revoked key or a known false positive.

What it does not do:

- It does not scan files, tool output, or anything other than the prompt text.
- It does not log or store the prompt.
- It is a safety net, not a guarantee. Unusual credential formats will not be detected.

## Disabling hooks

To turn off one or more of these hooks while keeping the plugin enabled, set the `AGENTIC_TOOLS_HOOKS_DISABLE` environment variable to a comma-separated list of hook names, or to `all`. The hook names are `stop-unsaved-work`, `session-behind-main`, and `secret-guard`. The simplest place to set it is the `env` block of a Claude Code settings file, for example `~/.claude/settings.json` or a project's `.claude/settings.json`:

```json
{
  "env": {
    "AGENTIC_TOOLS_HOOKS_DISABLE": "stop-unsaved-work,session-behind-main"
  }
}
```

Other options:

- Disable the whole agentic-tools plugin with `/plugin`, which also disables its skills.
- Set `"disableAllHooks": true` in a settings file to turn off every hook from every source.
- Remove the matching entry from `hooks/hooks.json` in a local checkout of the plugin.

## Tests

Run the test suite from the repository root:

```bash
bash hooks/tests/run-tests.sh
```

The suite pipes sample hook input into each script and checks the exit code and output. The git tests build throwaway repositories under a temporary directory, with a local bare repository acting as `origin`, so they need no network access. The suite runs twice, once with `jq` and once with the built-in fallback parser. Sample credentials are assembled at runtime so that no realistic token appears in the repository.
