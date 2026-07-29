# Knowledge Base Maintenance

## Required Recording

For every fork-specific change, create or update a Markdown record under
`skills/` in the same pull request or commit series. This includes application
behavior, configuration, dependency, platform, build, and tooling changes.

## Commit Structure

When a code, configuration, or dependency change requires a knowledge-base
update, create two commits in this order:

1. Commit the runtime change without files under `skills/`.
2. Commit the corresponding `skills/` updates separately.

The knowledge-base commit message must preserve the code commit's scope and
description, replacing only its leading conventional-commit type with
`skills`. For example, `feat(account): add some feature` is followed by
`skills(account): add some feature`; `fix: correct an issue` is followed by
`skills: correct an issue`. Do not use `docs` for these knowledge-base commits.

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

## Retention Rules

- Change records are maintainable behavior summaries, not execution logs. Keep
  the implementation constraints and the smallest set of validation commands
  and outcomes that establish confidence.
- Do not record routine retries, dependency-download output, device IDs,
  network endpoints, signing mismatches, installation steps, or other transient
  diagnostics unless they explain an active limitation that future maintainers
  must reproduce.
- Do not move transient logs to another knowledge-base record. Git history is
  the archive for one-off execution details; move information only when it is a
  reusable procedure for `workflows/` or a durable design decision for
  `architecture/`.
- Before adding a detail, verify that it is needed to change, validate,
  reproduce, or resolve future conflicts in the affected behavior. Omit it if
  it does not meet one of these purposes, and remove it when it becomes stale.