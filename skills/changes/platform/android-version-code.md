# Android Version Code

## Status

Active

## Scope

- Affected paths: `lib/scripts/build.ps1`
- Upstream relationship: fork-only

## Intent

Keep GitHub Release APKs installable after the fork's required upstream rebases rewrite commit history.

## Implementation

The release build script uses the UTC Unix timestamp in seconds for Android `versionCode` and `pili.time`. The displayed Android version name still includes the short commit hash. Do not derive `versionCode` from Git commit count because rebasing can reduce it and Android rejects the APK as a downgrade.

## Validation

`docker run --rm mcr.microsoft.com/powershell:7.5-ubuntu-24.04 pwsh -NoProfile -Command '$versionCode = [int]([DateTimeOffset]::UtcNow.ToUnixTimeSeconds()); ...'` produced `1785135729`, within Android's signed 32-bit integer range. `git diff --check` passed.

## Follow-up

The Unix timestamp must remain within Android's signed 32-bit `versionCode` limit.