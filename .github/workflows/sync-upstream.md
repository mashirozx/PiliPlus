---
name: Sync Upstream
description: Check upstream/main every 15 minutes, then promote a rebased main snapshot to release when needed.
on:
  schedule: every 15m
  workflow_dispatch:
    inputs:
      dry_run:
        description: Preview the synchronization without rebasing or pushing.
        required: false
        default: true
        type: boolean
      force_rebase_plan:
        description: Exercise the guarded rebase plan during a dry run even when upstream is current.
        required: false
        default: false
        type: boolean
      source_branch:
        description: Manual-only source branch to rebase; scheduled runs always use main.
        required: false
        default: main
        type: string
      force_release_rebase:
        description: Manual-only test override for release already containing upstream.
        required: false
        default: false
        type: boolean
      test_issue:
        description: Verify ISSUE_POST_TOKEN by opening and closing a test issue.
        required: false
        default: false
        type: boolean
      precheck_only:
        description: Run the scheduled upstream pre-check before the manual workflow.
        required: false
        default: false
        type: boolean
permissions:
  contents: read
  copilot-requests: write
engine: copilot
checkout: false
tools:
  bash:
    - git:*
    - jq
network:
  allowed:
    - defaults
    - github
concurrency:
  group: release-promotion-${{ github.repository }}
  cancel-in-progress: false
timeout-minutes: 15
max-ai-credits: 100
steps:
  - name: Skip agent when release is current
    if: ${{ github.event_name == 'schedule' || (github.event_name == 'workflow_dispatch' && github.event.inputs.precheck_only == 'true') }}
    env:
      GH_AW_SAFE_OUTPUTS: ${{ steps.set-runtime-paths.outputs.GH_AW_SAFE_OUTPUTS }}
    run: |
      set -euo pipefail

      mkdir -p "$(dirname "$GH_AW_SAFE_OUTPUTS")"
      repository_dir="$(mktemp -d)"
      trap 'rm -rf "$repository_dir"' EXIT
      git -C "$repository_dir" init --quiet
      git -C "$repository_dir" remote add origin "https://github.com/${GITHUB_REPOSITORY}.git"
      git -C "$repository_dir" remote add upstream https://github.com/bggRGjQaUbCoE/PiliPlus.git
      git -C "$repository_dir" fetch --quiet --no-tags origin refs/heads/release:refs/remotes/origin/release
      git -C "$repository_dir" fetch --quiet --no-tags upstream refs/heads/main:refs/remotes/upstream/main

      release_contains_upstream=false
      if git -C "$repository_dir" merge-base --is-ancestor upstream/main origin/release; then
        release_contains_upstream=true
      fi

      if [[ "$release_contains_upstream" == "true" ]]; then
        echo '{"type":"noop","message":"release contains the current upstream/main commit; skipped the agent."}' >> "$GH_AW_SAFE_OUTPUTS"
      else
        echo "release is missing upstream/main; continuing to the agent."
      fi
jobs:
  conclusion:
    pre-steps:
      - name: Fail incomplete upstream promotion
        if: ${{ always() }}
        env:
          DRY_RUN: ${{ github.event.inputs.dry_run || 'false' }}
          TEST_ISSUE: ${{ github.event.inputs.test_issue || 'false' }}
        run: |
          set -euo pipefail

          if [[ "$GITHUB_EVENT_NAME" == "workflow_dispatch" ]] && [[ "$DRY_RUN" == "true" || "$TEST_ISSUE" == "true" ]]; then
            echo "Intentional non-promotion run; skipping release verification."
            exit 0
          fi

          repository_dir="$(mktemp -d)"
          trap 'rm -rf "$repository_dir"' EXIT
          git -C "$repository_dir" init --quiet
          git -C "$repository_dir" remote add origin "https://github.com/${GITHUB_REPOSITORY}.git"
          git -C "$repository_dir" remote add upstream https://github.com/bggRGjQaUbCoE/PiliPlus.git
          git -C "$repository_dir" fetch --quiet --no-tags origin refs/heads/release:refs/remotes/origin/release
          git -C "$repository_dir" fetch --quiet --no-tags upstream refs/heads/main:refs/remotes/upstream/main

          if ! git -C "$repository_dir" merge-base --is-ancestor upstream/main origin/release; then
            echo "::error::upstream/main is newer than release; the rebase promotion failed or did not complete."
            exit 1
          fi

          echo "release contains the current upstream/main commit."
safe-outputs:
  report-failure-as-issue: false
  jobs:
    rebase-upstream:
      description: Rebase main onto verified upstream/main, automatically resolve conflicts in favor of upstream, document them in an issue, and force-push release. Never use this for a dry run.
      runs-on: ubuntu-latest
      permissions:
        contents: write
        issues: write
      env:
        FORK_PUSH_TOKEN: ${{ secrets.FORK_PUSH_TOKEN }}
        ISSUE_POST_TOKEN: ${{ secrets.ISSUE_POST_TOKEN }}
      inputs:
        upstream_sha:
          description: The full 40-character commit SHA currently at upstream/main.
          required: true
          type: string
      steps:
        - name: Verify and synchronize upstream
          run: |
            set -euo pipefail

            source_branch="main"
            release_branch="release"
            manual_source_branch="$(jq -r '.inputs.source_branch // "main"' "$GITHUB_EVENT_PATH")"
            force_release_rebase="$(jq -r '.inputs.force_release_rebase // "false"' "$GITHUB_EVENT_PATH")"
            test_issue="$(jq -r '.inputs.test_issue // "false"' "$GITHUB_EVENT_PATH")"

            if [[ "$GITHUB_EVENT_NAME" == "workflow_dispatch" ]]; then
              source_branch="$manual_source_branch"
            fi
            if [[ ! "$source_branch" =~ ^[A-Za-z0-9][A-Za-z0-9._/-]*$ ]]; then
              echo "Invalid source branch name."
              exit 1
            fi

            post_issue() {
              local title="$1"
              local body_file="$2"
              local issue_number
              local payload

              if [[ -z "$ISSUE_POST_TOKEN" ]]; then
                echo "ISSUE_POST_TOKEN is not configured."
                exit 1
              fi

              payload="$(jq -n --arg title "$title" --rawfile body "$body_file" '{title: $title, body: $body}')"
              issue_number="$(curl --fail-with-body --request POST \
                --header "Accept: application/vnd.github+json" \
                --header "Authorization: Bearer ${ISSUE_POST_TOKEN}" \
                --header "X-GitHub-Api-Version: 2022-11-28" \
                "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues" \
                --data "$payload" | jq -r '.number')"
              if [[ ! "$issue_number" =~ ^[0-9]+$ ]]; then
                echo "GitHub did not return an issue number."
                exit 1
              fi
              printf '%s\n' "$issue_number"
            }

            if [[ "$test_issue" == "true" ]]; then
              test_body="$(mktemp)"
              trap 'rm -f "$test_body"' EXIT
              printf '%s\n' \
                '# ISSUE_POST_TOKEN verification' \
                '' \
                'This issue was created automatically to verify the release-rebase' \
                'workflow credential and was closed immediately after creation.' \
                > "$test_body"
              test_number="$(post_issue "[automation test] ISSUE_POST_TOKEN verification" "$test_body")"
              curl --fail-with-body --request PATCH \
                --header "Accept: application/vnd.github+json" \
                --header "Authorization: Bearer ${ISSUE_POST_TOKEN}" \
                --header "X-GitHub-Api-Version: 2022-11-28" \
                "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${test_number}" \
                --data '{"state":"closed","state_reason":"completed"}' >/dev/null
              echo "Created and closed issue #${test_number} to verify ISSUE_POST_TOKEN."
              exit 0
            fi

            if [[ "$GITHUB_EVENT_NAME" == "workflow_dispatch" ]] && [[ "$(jq -r '.inputs.dry_run // "true"' "$GITHUB_EVENT_PATH")" == "true" ]]; then
              echo "Dry run requested; skipping rebase and push."
              exit 0
            fi

            if [[ -z "$FORK_PUSH_TOKEN" ]]; then
              echo "FORK_PUSH_TOKEN is not configured."
              exit 1
            fi

            mapfile -t requested_shas < <(jq -r '.items[] | select(.type == "rebase_upstream") | .upstream_sha' "$GH_AW_AGENT_OUTPUT" | sort -u)
            if [[ "${#requested_shas[@]}" -ne 1 ]] || [[ ! "${requested_shas[0]}" =~ ^[0-9a-f]{40}$ ]]; then
              echo "Expected exactly one full upstream commit SHA from the agent."
              exit 1
            fi

            git clone --no-checkout "https://github.com/${GITHUB_REPOSITORY}.git" repository
            cd repository
            git remote add upstream https://github.com/bggRGjQaUbCoE/PiliPlus.git
            git fetch --no-tags origin "refs/heads/${source_branch}:refs/remotes/origin/${source_branch}"
            git fetch --no-tags origin "refs/heads/${release_branch}:refs/remotes/origin/${release_branch}" || true
            git fetch --no-tags upstream main

            upstream_sha="$(git rev-parse upstream/main)"
            if [[ "$upstream_sha" != "${requested_shas[0]}" ]]; then
              echo "Upstream changed after the agent check; refusing to rebase a different commit."
              exit 1
            fi

            release_contains_upstream=false
            if git show-ref --verify --quiet "refs/remotes/origin/${release_branch}" && git merge-base --is-ancestor upstream/main "origin/${release_branch}"; then
              release_contains_upstream=true
            fi
            if [[ "$release_contains_upstream" == "true" ]]; then
              if [[ "$GITHUB_EVENT_NAME" != "workflow_dispatch" ]] || [[ "$force_release_rebase" != "true" ]]; then
                echo "${release_branch} already contains upstream/main; nothing to synchronize."
                exit 0
              fi
              echo "Manual force_release_rebase override accepted."
            fi

            if git show-ref --verify --quiet "refs/remotes/origin/${release_branch}"; then
              release_before_sha="$(git rev-parse "origin/${release_branch}")"
            else
              release_before_sha=""
            fi

            git checkout --detach "origin/${source_branch}"
            git config user.name "github-actions[bot]"
            git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
            conflict_detected=false
            conflict_files="$(mktemp)"
            conflict_hunks="$(mktemp)"
            conflict_resolutions="$(mktemp)"
            audit_branch="zzz/rebase-${upstream_sha}"
            trap 'rm -f "$conflict_files" "$conflict_hunks" "$conflict_resolutions"' EXIT

            resolve_rebase_conflicts() {
              local current_conflicts
              local replay_commit
              current_conflicts="$(git diff --name-only --diff-filter=U)"
              if [[ -z "$current_conflicts" ]]; then
                echo "Rebase stopped without merge conflicts; refusing automatic recovery."
                exit 1
              fi
              replay_commit="$(git rev-parse REBASE_HEAD)"

              conflict_detected=true
              while IFS= read -r conflict_file; do
                [[ -z "$conflict_file" ]] && continue
                encoded_path="$(printf '%s' "$conflict_file" | jq -sRr @uri)"
                printf '%s\n' "$conflict_file" >> "$conflict_files"
                {
                  printf '\n### %s\n\n' "$conflict_file"
                  git diff --cc --no-color -- "$conflict_file"
                } >> "$conflict_hunks"
                {
                  printf '### [`%s`](https://github.com/%s/blob/%s/%s)\n\n' "$conflict_file" "$GITHUB_REPOSITORY" "$audit_branch" "$encoded_path"
                  printf '**Decision:** Keep the upstream version and discard the conflicting hunk from the fork commit.\n\n'
                  printf '**Reasoning:** The automatic fallback cannot safely infer a semantic merge. Giving the verified upstream side priority avoids silently inventing a combined implementation; maintainers can reapply any required fork behavior after review.\n\n'
                  printf '**Replay being resolved:** [`%s`](https://github.com/%s/commit/%s)\n\n' "$replay_commit" "$GITHUB_REPOSITORY" "$replay_commit"
                  printf '**Applied command:** `git checkout --ours -- %s`, then `git add -- %s` and `git rebase --continue`. During this rebase, `ours` is the upstream side.\n\n' "$conflict_file" "$conflict_file"
                  printf '**Review path:** compare the [source version](https://github.com/%s/blob/%s/%s) with this linked resolved file before restoring any fork-specific behavior.\n\n' "$GITHUB_REPOSITORY" "$source_branch" "$encoded_path"
                } >> "$conflict_resolutions"
                # During rebase, ours is the upstream side; keep it as the deterministic fallback.
                git checkout --ours -- "$conflict_file"
                git add -- "$conflict_file"
              done <<< "$current_conflicts"
            }

            if ! git rebase upstream/main; then
              resolve_rebase_conflicts
              while ! GIT_EDITOR=true git rebase --continue; do
                resolve_rebase_conflicts
              done
            fi
            release_after_sha="$(git rev-parse HEAD)"

            if [[ "$release_after_sha" == "$release_before_sha" ]]; then
              echo "${release_branch} already matches the rebased ${source_branch}; skipping release update."
              exit 0
            fi

            git remote set-url origin "https://x-access-token:${FORK_PUSH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

            if [[ "$conflict_detected" == "true" ]]; then
              git fetch --no-tags origin "refs/heads/${audit_branch}:refs/remotes/origin/${audit_branch}" || true
              if git show-ref --verify --quiet "refs/remotes/origin/${audit_branch}"; then
                audit_before_sha="$(git rev-parse "origin/${audit_branch}")"
                git push --force-with-lease="refs/heads/${audit_branch}:${audit_before_sha}" origin "${release_after_sha}:refs/heads/${audit_branch}"
              else
                git push origin "${release_after_sha}:refs/heads/${audit_branch}"
              fi
            fi

            if [[ -n "$release_before_sha" ]]; then
              git push --force-with-lease="refs/heads/${release_branch}:${release_before_sha}" origin "HEAD:refs/heads/${release_branch}"
            else
              git push origin "HEAD:refs/heads/${release_branch}"
            fi

            if [[ "$conflict_detected" == "true" ]]; then
              issue_body="$(mktemp)"
              {
                printf '# Automatic upstream rebase conflict resolved\n\n'
                printf 'The release rebase used the deterministic fallback of keeping the upstream side (`git checkout --ours`) for each conflicted file. Review the resulting branch before treating the resolution as final.\n\n'
                printf '## Trace\n\n'
                printf -- '- Upstream: [`%s`](https://github.com/bggRGjQaUbCoE/PiliPlus/commit/%s)\n' "$upstream_sha" "$upstream_sha"
                printf -- '- Source: [`%s`](https://github.com/%s/commit/%s)\n' "$source_branch" "$GITHUB_REPOSITORY" "$(git rev-parse "origin/${source_branch}")"
                printf -- '- Resolved branch: [`%s`](https://github.com/%s/tree/%s)\n' "$audit_branch" "$GITHUB_REPOSITORY" "$audit_branch"
                printf -- '- Resolved commit: [`%s`](https://github.com/%s/commit/%s)\n' "$release_after_sha" "$GITHUB_REPOSITORY" "$release_after_sha"
                printf -- '- Resolution diff: [compare release before and after](https://github.com/%s/compare/%s...%s)\n\n' "$GITHUB_REPOSITORY" "${release_before_sha:-$(git merge-base upstream/main "$release_after_sha")}" "$release_after_sha"
                printf '## Resolution Decisions\n\n'
                cat "$conflict_resolutions"
                printf '## Conflicted Files\n\n'
                sort -u "$conflict_files" | while IFS= read -r conflict_file; do
                  encoded_path="$(printf '%s' "$conflict_file" | jq -sRr @uri)"
                  printf -- '- [`%s`](https://github.com/%s/blob/%s/%s)\n' "$conflict_file" "$GITHUB_REPOSITORY" "$audit_branch" "$encoded_path"
                done
                printf '\n## Captured Conflict Hunks\n\n```diff\n'
                sed -n '1,600p' "$conflict_hunks"
                printf '\n```\n'
              } > "$issue_body"
              conflict_issue_number="$(post_issue "Automated rebase conflict for ${upstream_sha:0:12}" "$issue_body")"
              echo "Created conflict issue #${conflict_issue_number}."
            fi

---

# Sync Upstream

Clone the public fork and compare the selected source branch, `origin/release`, and the
upstream repository `bggRGjQaUbCoE/PiliPlus` branch `main`. Use a temporary
directory outside the workspace and do not modify any clone.

1. Fetch `origin/release` when it exists and `upstream/main`. Determine whether
  the current `upstream/main` commit is already an ancestor of `origin/release`.
  Do not use `git cherry` or compare `main` when deciding whether synchronization
  is required.
2. Call the `noop` tool only when release contains `upstream/main`. Otherwise,
  inspect `origin/main` and its `AGENTS.md` plus
  `skills/workflows/upstream-rebase.md` guidance.
3. Only when `origin/main` can be rebased linearly, call `rebase_upstream` with
   the exact 40-character SHA of `upstream/main`. Do not edit, commit, rebase,
  tag, dispatch builds, or push from the agent workspace; the guarded
   safe-output job performs those operations after verifying the SHA.
4. If the rebase needs a conflict resolution or violates fork-specific guidance,
   do not call the safe-output tool. Call `noop` and explain that manual
   resolution is required.

For `workflow_dispatch`, treat the run as a preview even if upstream has new
commits: call `rebase_upstream` only to demonstrate the guarded plan. Its
safe-output job will detect `dry_run=true` and make no repository changes.

The workflow-dispatch input `force_rebase_plan` is
`${{ github.event.inputs.force_rebase_plan }}`.

The workflow-dispatch input `test_issue` is
`${{ github.event.inputs.test_issue }}`. When it is `true`, call
`rebase_upstream` with the current full upstream SHA immediately, before any
normal comparison or `noop` decision. The safe-output job will run only its
credential-verification path and will not modify repository state.

When `force_rebase_plan=true`, call `rebase_upstream` with the current full
upstream SHA even if release already contains it. This input is for testing only
and must never be used with `dry_run=false`.

When the workflow-dispatch input `test_issue=true`, call `rebase_upstream` with
the current full upstream SHA regardless of repository state. The safe-output
job will create and immediately close a credential-verification issue without
rebasing, tagging, dispatching a build, or pushing a branch.

When the workflow-dispatch input `force_release_rebase=true`, call
`rebase_upstream` even when release already contains upstream. This input is for
controlled rebase testing only and must not be used by scheduled runs.

The workflow-dispatch input `force_release_rebase` is
`${{ github.event.inputs.force_release_rebase }}`.
