# Release Push Build Dispatch

## Status

Active

## Scope

- Affected paths: `.github/workflows/auto-release.yml`.
- Upstream relationship: fork-only.

## Intent

Start the full fork release build whenever a commit is pushed to `release`.

## Implementation

- The workflow is limited to `release` push events and dispatches the existing
  `Build` workflow at the immutable release tag with every platform input
  explicitly enabled.
- It derives an unused tag from the three-component `pubspec.yaml` version and
  Beijing time in the `${version}-YYYY.MM.DD-HH.mm` format used by the manual
  `触发 build` command.
- It atomically creates the tag at the push event's `GITHUB_SHA` before
  dispatching the build. A failed tag creation waits for the next Beijing-time
  minute, so a release tag is never reused.
- Dispatch uses the job's `GITHUB_TOKEN` with `actions: write` and
  `contents: write`. The upstream synchronization workflow only updates
  `release`; its push event triggers this workflow and is the single automatic
  Build entry point.

## Validation

- `docker run --rm -v "$PWD:/workspace" -w /workspace
  rhysd/actionlint:1.7.10 -ignore SC2129 .github/workflows/auto-release.yml
  .github/workflows/build.yml` completed without errors. `SC2129` remains an
  unrelated pre-existing Android signing-style warning.

## Follow-up

None.