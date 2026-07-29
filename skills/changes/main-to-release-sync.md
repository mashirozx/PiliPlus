# Main to Release Synchronization

## Status

Active

## Scope

- Affected paths: `.github/workflows/sync-main-to-release.yml`.
- Upstream relationship: fork-only.

## Intent

Keep the fork's `release` branch exactly aligned with every pushed `main`
commit so release builds can consistently use the branch snapshot.

## Implementation

- A GitHub Actions `push` trigger is limited to `main`.
- The job checks out the triggering SHA and force-pushes that SHA to `release`.
- Authentication uses the existing `FORK_PUSH_TOKEN` secret; it must retain
  `Contents: Read and write` permission on this fork.
- The workflow shares the scheduled upstream-rebase workflow's repository
  concurrency group, preventing either release promotion from racing the other.

## Validation

- `docker run --rm -v "$PWD:/workspace" -w /workspace
  rhysd/actionlint:1.7.10 .github/workflows/sync-main-to-release.yml` completed
  without errors.

## Follow-up

The scheduled upstream-rebase automation may also update `release`; its later
promotion remains intentional and is separately documented in
`upstream-rebase-automation.md`.
