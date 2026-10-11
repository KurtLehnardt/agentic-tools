---
name: release
description: "Cut a versioned release end to end: merge PRs, bump every version source, tag, publish a GitHub release, update the local install, and smoke test it. Trigger: cut a release, new release, bump version, publish a version, tag a release, release and update my local install."
user-invocable: true
---

# /release: Versioned Release and Local Install

You are an **orchestrator** that cuts a new version of a versioned artifact (a CLI, library, Homebrew tap, npm or PyPI package, mobile app, or Claude Code plugin) and refreshes the local install. You dispatch subagents for the mechanical work and verify what they report. This skill is not `/deploy`. `/deploy` pushes a hosted web app to staging or production. `/release` produces a tagged version that users install.

## Usage

`/release [patch|minor|major|<x.y.z>] [--pr <n>] [--dry-run] [--no-local]`

- `patch`, `minor`, `major`, or an explicit `x.y.z` sets the bump. With none given, infer it from conventional commits since the last tag and state the reasoning in one short list of the commits that decided it. Any `feat` means minor, only `fix` means patch, and a `!` after the type or a `BREAKING CHANGE` footer means major. These special cases override the simple rule:
  - **0.x versions:** while the current version is below 1.0.0, a breaking change means minor instead of major, and other rules stay the same. Moving to 1.0.0 happens only when the user asks for it.
  - **Only chore, docs, style, test, or ci commits:** the range has no user-facing change. Ask the user whether to release at all, and if they say yes, default to patch.
  - **Non-conventional history:** if most commit subjects do not follow conventional commits, do not guess from keywords. Ask the user for the bump type. If the user cannot be asked, default to patch and state that reason.
  - **No prior tag:** this is the first release. Unless the user gave an explicit bump, use the current manifest version as is, without bumping it. If no manifest carries a version, use 0.1.0. Release notes then cover the whole history.
- `--pr <n>` merges that PR first. Open PRs named in the request are treated the same way.
- `--dry-run` prints every command that would run and executes none of the mutating ones. Preflight uses only read-only commands. In place of `git pull --ff-only` it runs `git fetch` and compares the local branch with its upstream using `git status -sb` or `git rev-list --count HEAD..@{u}`, and it says that it did so.
- `--no-local` skips Phase 6 and Phase 7.

## Safety Rules

- Never move, delete, or force-push an existing tag. If `vX.Y.Z` already exists, stop and report.
- Stop if any completed check on the HEAD commit failed. Do not retry around a red check. See the CI gate below.
- Ask the user once before pushing a major bump. Do not ask again for the same release.
- Under `--dry-run`, run only read-only commands (status, log, view, list, fetch) and print the rest. `git fetch` updates only remote-tracking refs and is allowed.

## Phase 1: PREFLIGHT

```bash
git status --porcelain                      # must be empty
git branch --show-current                   # must equal the default branch
gh repo view --json defaultBranchRef -q .defaultBranchRef.name
git pull --ff-only                          # under --dry-run: git fetch, then compare with upstream instead
gh auth status
git describe --tags --abbrev=0              # last tag, or none for a first release
```

If any check fails, stop and report which one. Do not fix a dirty tree or switch branches on the user's behalf.

### CI gate

The CI gate looks at the HEAD commit, not at the latest workflow run on the branch, because the latest run may belong to a different workflow or an older commit. Query both check runs and commit statuses for HEAD:

```bash
sha=$(git rev-parse HEAD)
gh api --paginate repos/{owner}/{repo}/commits/$sha/check-runs --jq '.check_runs[] | {name, status, conclusion}'
gh api --paginate repos/{owner}/{repo}/commits/$sha/status --jq '.statuses[] | {context, state}'
```

Rules:

1. Every completed check run must have a conclusion of `success`, `neutral`, or `skipped`. Every commit status must be `success`. Any other completed result stops the release and is reported by name.
2. If any check run is not completed (`queued` or `in_progress`) or any status is `pending`, wait and poll again. Do not treat pending as green and do not treat it as red.
3. If HEAD has no check runs and no statuses at all, the repo has no CI for this commit. Warn the user that nothing gates this release. Then run the project's local test command if one exists (`npm test`, `pytest -q`, `cargo test`, `make test`) and proceed only if it passes. If there is no test command either, say so in the report and proceed. Do not block forever on a repo that has no CI.

## Phase 2: MERGE PRs

Skip this phase when no PR is named.

- If the user wants a review, delegate each PR to the sibling `/review-pr <n> --merge` skill and wait for its merge result. Under `--dry-run`, print this `/review-pr` delegation and do not invoke it.
- Otherwise require every check on the PR to be green (`gh pr checks <n>`). Detect the repo's merge convention the same way `/review-pr` does: read the allowed methods from `gh api repos/{owner}/{repo}` (`allow_squash_merge`, `allow_merge_commit`, `allow_rebase_merge`) and compare them with the style of recent history (`git log --merges`, or single-parent commits with PR numbers in the subject for squash). Then merge with `gh pr merge <n> --<method> --delete-branch`. If only one method is allowed, use it. If the signals conflict, prefer what recent history shows.
- After merging, run `git pull --ff-only` and re-run the CI gate from Phase 1 on the new HEAD. Under `--dry-run`, print these commands and do not run them.

## Phase 3: DETECT AND BUMP VERSION SOURCES

Dispatch a **general-purpose** subagent to find every place a version lives and report the current value of each:

- `package.json` (and `package-lock.json`), `pyproject.toml`, `Cargo.toml` (and `Cargo.lock`)
- `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`
- a `VERSION` file
- a Homebrew formula (`version`, `url`, `sha256`) in a tap repo, when the project references one
- `app.json` (`version`, `ios.buildNumber`, `android.versionCode`) and `build.gradle` (`versionName`, `versionCode`) for mobile projects

Rules:

1. **Agreement check first.** If the sources disagree before the bump, stop and list each file with its value. Do not guess which one is right.
2. **Plugin staleness check.** For a Claude Code plugin, the installed copy under `~/.claude/plugins/cache/` only refreshes when `plugin.json` version changes. A plugin that changes without a version bump never reaches users. Compare `plugin.json` at the last tag with the current commit, using `git show <tag>:.claude-plugin/plugin.json`. With no prior tag there is nothing to compare against, so skip the comparison: the first release uses the manifest version as is, and `plugin.json` and `marketplace.json` must already agree on it. Otherwise, if files changed since the tag, the version must change in this release, and both `plugin.json` and `marketplace.json` must carry the new value.
3. Bump every detected source to the new version in one edit pass. Increment `versionCode` by one. Refresh lockfiles with the project's own tool (`npm install --package-lock-only`, `cargo update -w`).
4. Re-read every file and confirm all sources now match the new version.

## Phase 4: RELEASE NOTES

Collect commits and merged PRs since the last tag (`git log <tag>..HEAD --pretty='%s (%h)'` and `gh pr list --state merged`). Group them under Breaking Changes, Features, Fixes, and Other, with a PR number or short hash on each line. If `CHANGELOG.md` exists, add a `## vX.Y.Z (date)` section at the top in its existing style. Save the notes to a temp file for `gh release create`.

## Phase 5: COMMIT, TAG, PUBLISH

```bash
git add <bumped files> CHANGELOG.md
git commit -m "chore(release): vX.Y.Z"
git tag -a vX.Y.Z -m "vX.Y.Z"
git push origin <default> && git push origin vX.Y.Z
gh release create vX.Y.Z --title "vX.Y.Z" --notes-file <notes>  [artifacts...]
```

If the project has a build step that produces artifacts (tarballs, wheels, binaries, an IPA or APK), build them and attach them. For a Homebrew tap, compute the sha256 of the release tarball, update the formula in the tap repo, and push that change as well. Confirm a major bump with the user before the push.

## Phase 6: UPDATE LOCAL INSTALL

Pick the method from the project type. Skip this phase under `--no-local`.

| Project type | Command |
|--------------|---------|
| Homebrew tap | `brew update && brew upgrade <formula>` (use `brew reinstall <formula>` if upgrade reports nothing) |
| npm global | `npm i -g <package>@X.Y.Z` |
| pipx | `pipx upgrade <package>` |
| Claude Code plugin | `claude plugin marketplace update <marketplace>` then `claude plugin update <plugin>@<marketplace>` |

The `claude plugin` subcommands exist as of CLI 2.1.287. Run `claude plugin update --help` first to confirm the syntax on the installed CLI. A plugin update needs a Claude Code restart to apply, so tell the user to restart.

## Phase 7: SMOKE TEST

1. Read the installed version string (`<bin> --version`, `brew info`, `pipx list`, or the version in the `~/.claude/plugins/cache/` path for a plugin) and confirm it equals the new tag without the leading `v`.
2. Run the project's basic command or test (`<bin> --help`, `npm test`, `pytest -q`, `cargo test`).
3. If the installed version is still the old one, report the failure with the command output. Do not retry more than twice.

## Phase 8: REPORT

Report in this order: version, tag URL, release URL, local install result, smoke result. Name any phase that was skipped and why.
