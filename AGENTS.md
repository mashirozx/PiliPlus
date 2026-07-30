# PiliPlus Fork Agent Guide

This repository is a fork of `bggRGjQaUbCoE/PiliPlus`. Preserve a linear
commit history where local commits remain on top of the current upstream
branch.

## Read First

Read the applicable documents in `skills/` before making a change:

- `skills/workflows/upstream-rebase.md` for upstream synchronization.
- `skills/workflows/android-debugging.md` for Android device debugging.
- `skills/workflows/worktree-management.md` before creating or removing a
  worktree.
- `skills/maintenance/knowledge-base.md` for knowledge-base rules.
- Relevant records under `skills/changes/` and `skills/architecture/`.

## Git Workflow

- Treat `upstream` as the source project and `origin` as this fork.
- Synchronize with `git fetch upstream` followed by `git rebase upstream/main`.
- Never merge `upstream/main` into local work. Resolve rebase conflicts, run
  focused validation, then update the affected knowledge records.
- Keep local commits above the upstream tip. Do not rewrite, reset, or discard
  user changes unless explicitly requested.
- Push a rebased branch with `git push --force-with-lease origin main` only
  when the user explicitly asks to publish it.

## Execution Environment

- No local development environment is assumed to be available.
- Unless the task explicitly states otherwise, run all required code execution
  through Docker. This includes dependency installation, code generation,
  formatting, static analysis, tests, builds, and project scripts.
- Prefer existing repository Docker configuration. When adding or changing
  container commands, record the image, command, mounted paths, and validation
  result in the applicable `skills/` record.
- Genymotion is approved for interactive Android device debugging, installing
  built artifacts, and manual smoke tests. Keep build, dependency, and
  automated test commands in Docker unless the task explicitly permits a host
  command.

## Local Knowledge Base

`skills/` owns fork-specific knowledge and maintenance material. Keep it
structured by purpose:

- `skills/workflows/`: repeatable operational procedures.
- `skills/architecture/`: durable design decisions and subsystem knowledge.
- `skills/changes/`: one record per fork-specific feature, behavior change, or
  non-trivial fix.
- `skills/maintenance/`: conventions for maintaining this knowledge base.

Runtime code belongs in its normal project location, not under `skills/`.
Every local code, configuration, dependency, build, or behavior change must
also add or update a concise record under `skills/` in the same change. Link
records to affected paths, describe the reason and validation, and update them
when later work supersedes their guidance.