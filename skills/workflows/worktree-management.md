# Worktree Management Workflow

## Objective

Keep VS Code's multi-root workspace synchronized with the fork's sibling
worktrees.

## Procedure

1. Create the sibling worktree with `git worktree add`.
2. In the same operation, add its `./PiliPlus-*` relative path to `folders` in
   `../PiliPlus.code-workspace`.
3. Preserve existing folder entries and add the new path only when it is not
   already present.
4. Validate the workspace definition:

   ```sh
   plutil -lint ../PiliPlus.code-workspace
   ```

5. When removing a sibling worktree, remove its matching folder entry from
   `../PiliPlus.code-workspace` after `git worktree remove`, then rerun the
   validation command.

## Guardrails

- VS Code multi-root workspace definitions do not support directory glob
  patterns; every sibling worktree needs an explicit entry.
- A worktree is not ready until its workspace entry has been synchronized, so
  it appears with the other fork worktrees after the next workspace reload.
- Preserve unrelated workspace settings and existing folder entries.