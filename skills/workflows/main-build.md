# Main Build Dispatch

## Objective

Manually dispatch the fork's full release build from its `main` branch using
the local GitHub CLI.

## Scope

- Target repository: `mashirozx/PiliPlus`.
- Workflow: `Build` (`.github/workflows/build.yml`).
- Ref: `main`.
- Upstream relationship: fork-only. Never dispatch a build against
  `bggRGjQaUbCoE/PiliPlus`.

## Procedure

Run the following from the repository root. It derives the release version
from `pubspec.yaml`, uses the current Beijing time, verifies the tag is unused,
and explicitly enables every platform build:

```sh
version=$(sed -nE 's/^version: ([0-9]+\.[0-9]+\.[0-9]+)\+.*/\1/p' pubspec.yaml)
tag="$version-$(TZ=Asia/Shanghai date '+%Y.%m.%d-%H.%M')"
[[ "$tag" =~ ^[0-9]+\.[0-9]+\.[0-9]+-[0-9]{4}\.[0-9]{2}\.[0-9]{2}-[0-9]{2}\.[0-9]{2}$ ]]
[[ $(gh api "repos/mashirozx/PiliPlus/git/matching-refs/tags/$tag" --jq 'length') == 0 ]]
gh workflow run Build --repo mashirozx/PiliPlus --ref main \
  -f build_android=true -f build_ios=true -f build_mac=true \
  -f build_win_x64=true -f build_linux_x64=true -f tag="$tag"
```

If the tag check fails, wait until the next Beijing-time minute and run the
same command again. Do not reuse an existing release tag.

## Constraints

- The tag must be `${version}-YYYY.MM.DD-HH.mm`, with a three-component
  `version` from `pubspec.yaml` and Beijing time (`Asia/Shanghai`).
- Keep every boolean input explicit; do not rely on CLI or workflow defaults.
- Use `gh workflow run`, not direct GitHub API dispatch calls or an upstream
  repository remote.

## Validation

After dispatching, identify the run with:

```sh
gh run list --repo mashirozx/PiliPlus --workflow Build --branch main --limit 1
```

## Follow-up

None.