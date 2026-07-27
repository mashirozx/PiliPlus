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

- The `release_changelog` job waits for all Build platform jobs to finish, then
  updates the release once so concurrent asset uploads cannot overwrite its
  notes.
- It resolves the current and previous release commits and their Git trees. The
  notes list only `+` commits from `git cherry <previous> <current>`, which uses
  patch IDs rather than commit SHA equality.
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

## Follow-up

None.