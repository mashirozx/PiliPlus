# Knowledge Base Maintenance

## Required Recording

For every fork-specific change, create or update a Markdown record under
`skills/` in the same pull request or commit series. This includes application
behavior, configuration, dependency, platform, build, and tooling changes.

## Record Template

```md
# Change Title

## Status

Active | Superseded | Removed

## Scope

- Affected paths: `path/to/file`
- Upstream relationship: fork-only | upstream-compatible | conflict resolution

## Intent

Why this fork needs the change.

## Implementation

Key behavior, constraints, and integration points.

## Validation

Commands or checks run and their result.

## Follow-up

Known limitations, migration work, or `None`.
```

## Placement Rules

- Put procedural material in `workflows/`.
- Put decisions expected to guide future implementations in `architecture/`.
- Put feature and fix history in `changes/`; add an area subdirectory once a
  group has multiple related records.
- Link to repository-relative paths and state whether the behavior is fork-only
  or should be proposed upstream.
- Mark stale records `Superseded` or `Removed`; retain a link to the successor
  when one exists.