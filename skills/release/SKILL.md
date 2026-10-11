---
name: release
description: "Cut a versioned release end to end: merge PRs, bump every version source, tag, publish a GitHub release, update the local install, and smoke test it. Trigger: cut a release, new release, bump version, publish a version, tag a release, update my local install."
user-invocable: true
---

# /release: Versioned Release and Local Install

You are an **orchestrator** that cuts a new version of a versioned artifact (a CLI, library, Homebrew tap, npm or PyPI package, mobile app, or Claude Code plugin) and refreshes the local install. You dispatch subagents for the mechanical work and verify what they report. This skill is not `/deploy`. `/deploy` pushes a hosted web app to staging or production. `/release` produces a tagged version that users install.

## Usage

`/release [patch|minor|major|<x.y.z>] [--pr <n>] [--dry-run] [--no-local]`

- `patch`, `minor`, `major`, or an explicit `x.y.z` sets the bump. With none given, infer it from conventional commits since the last tag. Any `feat` means minor, only `fix` means patch, and a `!` after the type or a `BREAKING CHANGE` footer means major. State the reasoning in one short list of the commits that decided it.
- `--pr <n>` merges that PR first. Open PRs named in the request are treated the same way.
- `--dry-run` prints every command that would run and executes none of them.
- `--no-local` skips Phase 6 and Phase 7.

## Safety Rules

- Never move, delete, or force-push an existing tag. If `vX.Y.Z` already exists, stop and report.
- Stop if CI is red on HEAD. Do not retry around a red check.
- Ask the user once before pushing a major bump. Do not ask again for the same release.
- Under `--dry-run`, run only read-only commands (status, log, view, list) and print the rest.

## Phase 1: PREFLIGHT

```bash
git status --porcelain                      # must be empty
git branch --show-current                   # must equal the default branch
gh repo view --json defaultBranchRef -q .defaultBranchRef.name
git pull --ff-only
gh auth status
gh run list --branch <default> --limit 1 --json conclusion,status   # must be success
git describe --tags --abbrev=0              # last tag, or none for a first release
```

If any check fails, stop and report which one. Do not fix a dirty tree or switch branches on the user's behalf.

## Phase 2: MERGE PRs

Skip this phase when no PR is named.

- If the user wants a review, delegate each PR to the sibling `/review-pr` skill and wait for its merge result.
- Otherwise require every check on the PR to be green (`gh pr checks <n>`) and merge with `gh pr merge <n> --squash --delete-branch`.
- After merging, run `git pull --ff-only` and re-run the CI check from Phase 1 on the new HEAD.

## Phase 3: DETECT AND BUMP VERSION SOURCES

Dispatch a **general-purpose** subagent to find every place a version lives and report the current value of each:

- `package.json` (and `package-lock.json`), `pyproject.toml`, `Cargo.toml` (and `Cargo.lock`)
- `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`
- a `VERSION` file
- a Homebrew formula (`version`, `url`, `sha256`) in a tap repo, when the project references one
- `app.json` (`version`, `ios.buildNumber`, `android.versionCode`) and `build.gradle` (`versionName`, `versionCode`) for mobile projects

Rules:

1. **Agreement check first.** If the sources disagree before the bump, stop and list each file with its value. Do not guess which one is right.
2. **Plugin staleness check.** For a Claude Code plugin, the installed copy under `~/.claude/plugins/cache/` only refreshes when `plugin.json` version changes. A plugin that changes without a version bump never reaches users. Compare `plugin.json` at the last tag with the current commit. If files changed since the tag, the version must change in this release, and both `plugin.json` and `marketplace.json` must carry the new value.
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
