# Main Push Build Dispatch

## Status

Active

## Scope

- Affected paths: `.github/workflows/dispatch-main-build.yml`.
- Upstream relationship: fork-only.

## Intent

Start the full fork release build whenever a commit is pushed to `main`.

## Implementation

- The workflow is limited to `main` push events and dispatches the existing
  `Build` workflow at `main` with every platform input explicitly enabled.
- It derives an unused tag from the three-component `pubspec.yaml` version and
  Beijing time in the `${version}-YYYY.MM.DD-HH.mm` format used by the manual
  `触发 build` command.
- Dispatch uses the job's `GITHUB_TOKEN` with `actions: write`, matching the
  existing upstream synchronization automation. `FORK_PUSH_TOKEN` is reserved
  for Git ref updates because it does not have Actions access.
- The workflow serializes dispatches and waits for a new minute when a tag is
  already present, so a release tag is never reused.

## Validation

- `docker run --rm -v "$PWD:/workspace" -w /workspace
  rhysd/actionlint:1.7.10 .github/workflows/dispatch-main-build.yml` completed
  without errors.

## Follow-up

None.
