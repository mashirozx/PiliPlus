# Android Debug Entrypoints

## Status

Active

## Scope

- Affected paths: `tool/android_debug_install.sh`,
  `tool/android_hot_reload_start.sh`, `tool/android_hot_reload_trigger.sh`,
  `tool/android_dev_container_pause.sh`,
  `tool/android_dev_container_resume.sh`,
  `tool/docker_flutter.sh`, and `skills/workflows/android-debugging.md`.
- Upstream relationship: fork-only.

## Intent

Provide concise, repeatable commands for installing a Docker-built debug APK
and requesting individual Dart hot reloads on the local Genymotion emulator.

## Implementation

- The Android scripts use `PILIPLUS_DOCKER_CONTAINER` to reuse the
  `piliplus-android-dev` container, preserving the Gradle daemon as well as the
  persisted SDK and dependency caches.
- `tool/android_debug_install.sh` builds a debug APK and installs it through
  container-local ADB.
- `tool/android_hot_reload_start.sh` starts container-local ADB and `flutter
  run` in the background. Its PID and log are ignored state beneath
  `build/android-hot-reload/`.
- `tool/android_hot_reload_trigger.sh` sends `r` over a FIFO inside the reusable
  container, causing the existing Flutter session to reload saved Dart sources
  without rebuilding or reinstalling the APK.
- `tool/android_dev_container_pause.sh` ends an active hot-reload session and
  pauses the reusable container. `tool/android_dev_container_resume.sh` unpauses
  it, starts it if stopped, or recreates it if removed. Pausing preserves
  process state; on this OrbStack workstation, it can also reclaim inactive
  container memory.
- All scripts default to `host.docker.internal:6555`; set
  `PILIPLUS_ANDROID_DEVICE` for another emulator endpoint.
- `tool/docker_flutter.sh` checks out Flutter `3.47.2`, matching the minimum
  Dart SDK version required by `pubspec.yaml`, using a version-specific SDK
  cache so older Flutter worktrees remain untouched.
- The reusable container installs PowerShell when absent. Android debug install
  and hot reload apply `lib/scripts/patch.ps1 android` to the cached Flutter
  SDK and refreshed `material_ui` package before compiling, matching CI.
- `patch.ps1` honors an explicit `PUB_CACHE`, allowing the Docker workflow to
  patch `material_ui` in `/cache/pub` rather than an unused home-directory
  default.

## Validation

- `sh -n tool/android_debug_install.sh tool/android_hot_reload_start.sh
  tool/android_hot_reload_trigger.sh` and `git diff --check` completed without
  errors.
- `tool/android_debug_install.sh` built the debug APK and installed it on the
  Genymotion emulator successfully.
- `tool/android_hot_reload_start.sh` reached `Flutter run key commands`; the
  trigger script completed a no-source-change hot reload in 642 ms through the
  container-local FIFO.
- A fresh reusable-container debug build and install completed in 80.4 seconds;
  the next unchanged invocation completed in 29.1 seconds, with Gradle taking
  20.2 seconds. This demonstrates the benefit of retaining the Gradle daemon.
- `tool/android_dev_container_pause.sh` and
  `tool/android_dev_container_resume.sh` transitioned the idle development
  container from `running` to `paused` and back to `running` successfully.
- After rebasing onto upstream `06b88943c`, `tool/docker_flutter.sh flutter pub
  get` initially failed because Flutter `3.44.8` provides Dart `3.12.2`, while
  the synchronized `pubspec.yaml` requires Dart `>=3.13.0`; the script now
  fetches Flutter `3.47.2`.
- `tool/android_debug_install.sh` rebuilt and connected to Genymotion, but the
  unpatched SDK lacked framework APIs used by the app. The debug entry points
  now execute the same Android patch sequence as CI before compilation.
- The patched debug workflow built `app-debug.apk`, installed it to Genymotion,
  and launched `MainActivity`. The app rendered a video detail page, displayed
  the coin action, and its tap produced the expected unauthenticated-account
  prompt without crashing.

## Follow-up

Use a new hot-reload session after native Android, Gradle, manifest,
dependency, or launcher-icon changes.

Keep the container running during a development conversation. Do not pause it
after individual development actions unless the user explicitly requests it or
confirms that development is complete.