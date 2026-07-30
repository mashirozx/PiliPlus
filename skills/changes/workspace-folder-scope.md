# Workspace Folder Scope

## Status

Active

## Scope

- Affected paths: `../PiliPlus.code-workspace`
- Upstream relationship: fork-only

## Intent

Open the primary fork and its sibling `PiliPlus-*` worktrees together in VS Code.

## Implementation

The workspace explicitly lists each currently present matching sibling folder.
VS Code multi-root workspace definitions do not support glob patterns.

Follow `skills/workflows/worktree-management.md` whenever adding or removing
a worktree. The workflow keeps `../PiliPlus.code-workspace` synchronized with
the sibling worktrees.

## Validation

`plutil -lint ../PiliPlus.code-workspace` reports valid JSON syntax, and the
new directory appears once in `folders`.

## Follow-up

None.