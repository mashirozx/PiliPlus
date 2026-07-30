# Upstream Rebase Workflow

## Objective

Keep the fork as a linear sequence: the current `upstream/main` history first,
then this fork's local commits.

## Procedure

1. Start from a clean working tree. Preserve or commit local work before
   synchronization.
2. Fetch the source repository:

   ```sh
   git fetch upstream
   ```

3. Rebase local commits onto the source tip:

   ```sh
   git rebase upstream/main
   ```

4. For each conflict, resolve the intended combined behavior, stage the
   resolution, and continue with `git rebase --continue`. Use
   `git rebase --abort` to return to the pre-rebase state when necessary.
5. Run focused validation for resolved areas, then update any affected
   `skills/changes/` or `skills/architecture/` records.
6. Review the linear result with:

   ```sh
   git log --oneline upstream/main..HEAD
   ```

7. Publish only on request. Because rebase rewrites local commit IDs, use:

   ```sh
   git push --force-with-lease origin main
   ```

## Fork Conflict Map

- Consult `skills/changes/platform/branding-and-identity.md` for Android,
   Apple, Windows, and launcher-icon identity conflicts. Regenerate icon
   binaries from their SVG sources rather than merging binary resources.
- Consult `skills/changes/platform/android-launcher-resource-cycle.md` for
   Android adaptive-icon XML or drawable conflicts.
- Consult `skills/changes/platform/linux-package-executable.md` for Linux
   CMake, release workflow, or package lifecycle conflicts.

## Guardrails

- `upstream` is permanently read-only: use it only to fetch, inspect, diff, and
   rebase source history. The local account has no upstream write permission.
- Never push, create or delete tags, create releases, dispatch workflows, or
   call write-capable GitHub APIs against `bggRGjQaUbCoE/PiliPlus`. Direct every
   write or Actions operation to the fork `origin` (`mashirozx/PiliPlus`).
- Do not merge `upstream/main` into `main`.
- Do not use plain `--force` when publishing rewritten history.
- Do not include generated build output or unrelated upstream cleanup in local
  commits.