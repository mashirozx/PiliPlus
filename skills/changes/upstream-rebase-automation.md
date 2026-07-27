# Scheduled Sync Upstream Automation

## Status

Active

## Scope

- Affected paths: `.gitattributes`, `.github/aw/actions-lock.json`,
  `.github/workflows/sync-upstream.md`, and its generated
  `.github/workflows/sync-upstream.lock.yml`.
- Upstream relationship: fork-only.

## Intent

Check the upstream project every 15 minutes and promote an upstream-rebased
`main` snapshot to this fork's `release` branch without exposing a repository
write token to the GitHub Copilot CLI runtime.

## Implementation

- The GH-AW Markdown workflow uses the Copilot engine to compare `origin/main`,
  `origin/release`, and `bggRGjQaUbCoE/PiliPlus` `main`. It never pushes to
  `main`.
- `bggRGjQaUbCoE/PiliPlus` is permanently read-only upstream: it is used only
  for source reads and fetches. The local account has no write permission there;
  tags, releases, workflow dispatches, pushes, and every other write-capable
  GitHub operation must target fork `origin` (`mashirozx/PiliPlus`).
- Upstream freshness is determined solely by whether `upstream/main` is an
  ancestor of `origin/release`. The current `main` commit is never used as the
  freshness baseline; it is only the source that the safe-output job rebases
  after an update is detected.
- Scheduled runs first perform the `release` versus `upstream/main` ancestry
  check with Git alone. When release already contains upstream, the step writes
  a GH-AW `noop` safe output and the agent never starts, avoiding AI-credit use
  for synchronized checks. The 15-minute cadence provides four independent
  delivery opportunities per hour when GitHub delays or drops one scheduled
  event. Because this check runs before GH-AW's normal safe-output setup, it
  creates the output directory itself. Manual dispatches still run the agent so
  dry runs and the explicit test inputs keep their intended behavior. The manual
  `precheck_only` input executes this same deterministic check before the normal
  manual workflow: it emits `noop` when synchronized and continues to the agent
  when upstream is newer.
- The agent clones repositories only for read-only comparison. It requests the
  `rebase-upstream` custom safe output only after identifying a new upstream
  commit not already present in `release`. The safe-output job rebases
  `origin/main` onto verified `upstream/main` and force-pushes only `release`.
- Upstream reads use its public HTTPS URL and require no token. The separate
  safe-output job owns `contents: write` and `actions: write`, uses the
  `FORK_PUSH_TOKEN` secret only to publish Git refs to this fork, and uses its
  short-lived `GITHUB_TOKEN` with the declared `actions: write` permission to
  dispatch the build. It verifies the requested SHA after a fresh fetch,
  rebases linearly, and publishes with `--force-with-lease`.
- After a successful release update, it derives the app version from
  `pubspec.yaml`, creates a Git-valid Beijing-time tag in the shared
  `${version}-YYYY.MM.DD-HH.mm` format, and dispatches `build.yml` at that tag
  with every platform build enabled. It skips both tag and build when `release`
  is unchanged. Manually dispatched builds use the same tag format.
- If Git reports merge conflicts, the safe-output job captures the conflicted
  files and combined diff hunks, resolves each file by retaining the upstream
  side (`git checkout --ours` during rebase), and continues the rebase. Before
  applying that fallback, it records a per-file decision: the discarded replay
  commit, the exact command, the upstream-priority rationale, and a link to the
  final file on the audit branch. It then pushes the resolved result to
  `rebase-<full-upstream-sha>` and uses `ISSUE_POST_TOKEN` to create an issue
  linking the branch, commits, comparison diff, per-file decisions, affected
  files, and captured conflict hunks before releasing the result.
- `.gitattributes` marks GH-AW lock files as generated and uses `merge=ours` to
  prevent generated workflow conflicts from obscuring the Markdown source.
- `.github/aw/actions-lock.json` records the resolved GH-AW setup action SHA so
  strict compilation reproduces the generated workflow without action-version
  drift.
- Scheduled runs may update `release`; manually dispatched runs default to
  `dry_run=true` and skip rebase, release push, tagging, and build dispatch.
  Local `act` tests must use this manual preview path without `--bind`, so the
  host worktree cannot be changed.
- The generated `conclusion` job independently fetches `release` and
  `upstream/main` after all safe-output work completes. A non-preview run fails
  when `release` still does not contain upstream, covering exhausted AI credits,
  agent no-ops, and any failed or incomplete promotion. Manual dry runs and
  `test_issue` credential checks are intentionally excluded.
- The manual-only `force_rebase_plan` input defaults to `false` and exists only
  to test the safe-output dry-run guard when the fork is already current. It
  must remain paired with `dry_run=true`.
- Manual-only `source_branch` and `force_release_rebase` inputs support
  controlled end-to-end rebase tests without modifying `main`. `test_issue`
  verifies `ISSUE_POST_TOKEN` by opening and immediately closing a test issue;
  it does not rebase, push, tag, or dispatch builds.

## Validation

- CI scenario procedure: do not fetch or compare upstream in a developer
  worktree. First wait for a scheduled run on `main` and inspect its Action
  logs. If it finds a real upstream advance, validate that real promotion and
  do not create a fixture. Only after a synchronized scheduled run emits the
  `release already contains the current upstream/main commit` noop may a
  disposable remote fixture be used to exercise the stale-upstream and
  modify/modify-conflict paths. Run each fixture through the remote workflow,
  capture the Action URL, release SHA, tag, audit branch, and conflict issue,
  then restore the original release SHA and delete every fixture ref and test
  tag. Never modify `main` for a fixture.
- GitHub Actions run `30257102693` exercised the manual `precheck_only` entry
  on `d797434f7`. It detected that `upstream/main` was newer than `release` and
  exposed an incorrect pre-check-only failure path before the Copilot CLI step;
  no fixture, release update, tag, or build dispatch was created. The current
  workflow removes that failure path, so upstream advances continue to the
  normal agent-driven rebase flow and still suppress simulated tests.
- `docker run --rm -v "$PWD:/workspace" -v "$HOME/.config/gh:/root/.config/gh:ro"
  -w /workspace alpine:3.21 sh -c 'apk add --no-cache github-cli git && gh
  extension install github/gh-aw --pin v0.83.1 && gh aw compile --strict
  .github/workflows/sync-upstream.md'` completed with zero errors and zero
  warnings. The generated schedule is `8/15 * * * *`, providing four staggered
  delivery attempts per hour.
- The generated safe-output job was inspected to confirm it has `actions: write`,
  uses fixed `main` and `release` branch names, force-pushes only `release`, and
  dispatches `build.yml` with the generated release tag. A live promotion test
  remains pending because it creates `release`, a release tag, and all platform
  builds.
- Security review: `ISSUE_POST_TOKEN` is a newly approved restricted secret. It
  is scoped only to the safe-output job and is sent exclusively to GitHub's
  create and close Issue endpoints; it is never passed to the Copilot agent,
  printed, or used for Git operations or build dispatch.
- `act workflow_dispatch -W .github/workflows/sync-upstream.lock.yml --dryrun
  --input dry_run=true --container-daemon-socket -` did not create a container
  or execute the workflow. `act` v0.2.89 rejects the generated workflow before
  execution because it does not recognize GitHub's `copilot-requests` permission
  or GH-AW's generated `concurrency.queue` field.
- GitHub Actions run `30241476855` dispatched with `dry_run=false` on
  `copilot/debug-upstream-rebase` successfully exercised the real safe-output
  rebase: it replayed four commits, pushed the rewritten debug branch from
  `c72db2ce7` to `35667fe3c`, and restored upstream commit `f1b79eea`. The
  remote `main` SHA remained `b676d67a` throughout the test.
- GitHub Actions run `30248117544` confirmed that a release promotion rebased
  `main` onto upstream commit `e4e70370d`, force-pushed `release`, and created
  tag `2.1.0-2026.07.27-08-03`. Its build dispatch failed with `403` because
  `FORK_PUSH_TOKEN` lacks the required Actions access; the workflow now uses
  the safe-output job's `GITHUB_TOKEN` instead. A follow-up live promotion is
  required to verify the corrected dispatch.
- GitHub Actions run `30251246100` confirmed the no-op path left `release` and
  tags unchanged, but exposed that the agent cannot honor
  `force_release_rebase` unless its actual workflow-dispatch value is rendered
  into the Markdown prompt. The prompt now explicitly interpolates that value.
- GitHub Actions run `30251529656` confirmed that the force override rebased the
  isolated source and published release commit `9e1bb249e` plus tag
  `2.1.0-2026.07.27-08-55`. Build dispatch then failed before its HTTP request
  because the safe-output shell did not expose `GITHUB_TOKEN`; the job now maps
  `github.token` into that environment variable. A follow-up promotion is
  required to verify the dispatch.
- GitHub Actions run `30248841690` completed the synchronized-release no-op
  path without changing `release` or creating a tag.
- GitHub Actions run `30251896280` completed a no-conflict promotion from an
  isolated source branch. It published release commit `0ab05b263`, tag
  `2.1.0-2026.07.27-09-00`, and dispatched Build run `30252127894` using that
  exact tag and commit.
- GitHub Actions run `30252625379` completed a deliberate modify/modify conflict
  on `lib/utils/image_utils.dart`. It retained upstream's `FutureOr` import,
  published release and audit branch `9777ed203`, created tag
  `2.1.0-2026.07.27-09-11`, dispatched Build run `30252873255`, and opened
  Issue #3 with the upstream/source/resolution links, conflict-file link, and
  combined diff hunk. The disposable source branches were deleted afterward.
- An initial manual Build dispatch to the upstream repository
  `bggRGjQaUbCoE/PiliPlus` with Beijing-time tag
  `2.1.0-2026.07.27-20.08` was rejected with HTTP `403`; the local GitHub CLI
  account `moezhx` had only effective `READ` access there. The fork `origin` is
  `mashirozx/PiliPlus`, where the same account has `WRITE` access. A manual
  dispatch from `origin/main` created Build run `30265475015` with tag
  `2.1.0-2026.07.27-20.19`. Dispatching through GitHub CLI must target `origin`,
  and web and CLI authentication contexts must be checked independently.
- A prior non-conflicting test accidentally published tag
  `2.1.0-2026.07.27-09-05`; its in-progress build was canceled and that tag was
  deleted before the final conflict validation.

## Follow-up

- Configure `FORK_PUSH_TOKEN` as a fine-grained token with this fork's
  `Contents: Read and write` and `Actions: Read and write` permissions, plus an
  `ISSUE_POST_TOKEN` with `Issues: Read and write`. Also configure either
  `permissions.copilot-requests: write` access or the `COPILOT_GITHUB_TOKEN`
  repository secret required by the Copilot engine.
