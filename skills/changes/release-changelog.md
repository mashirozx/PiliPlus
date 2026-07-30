# Release Changelog

## Status

Active

## Scope

- Affected paths: `.github/workflows/build.yml`.
- Upstream relationship: fork-only.

## Intent

Show the changes unique to each fork release in its GitHub Release body without
listing rebased or cherry-picked equivalents twice.

## Implementation

- The `release_changelog` job starts alongside the platform builds and waits up
  to one hour for any platform to create the tagged release. It then updates the
  release once; later concurrent asset uploads do not overwrite its notes.
- Every tagged dispatch first verifies that the supplied tag resolves to
  `GITHUB_SHA`; all release-producing jobs depend on this verification. The
  changelog resolves the current release commit from that tag after fetching
  tags, and fails if it does not still equal `GITHUB_SHA`. The previous release
  commit is resolved from its tag; both commits' Git trees are checked before
  comparison. The notes list only `+` commits from `git cherry <previous>
  <current>`, which uses patch IDs rather than commit SHA equality.
- Each entry is emitted as `- [hash](commit-link) subject`. When no prior
  release or no unique patch exists, the body states that condition explicitly.

## Validation

- An isolated Docker Git fixture confirmed that `git cherry previous current`
  marks an equivalent patch with a different SHA as `-` and a current-only patch
  as `+`.
- `docker run --rm -v "$PWD:/workspace" -w /workspace
  rhysd/actionlint:1.7.10 -ignore SC2129 .github/workflows/build.yml` completed
  without changelog-workflow diagnostics. `SC2129` is pre-existing in the
  Android signing step.
- GitHub Actions job `90788488396` failed because release tag
  `2.1.0-2026.07.30-13.30` was not fetchable after `gh release view` succeeded.
  Comparing its `GITHUB_SHA` with tag `2.1.0-2026.07.30-13.06` produced the four
  expected rebase commits.

## Follow-up

None.