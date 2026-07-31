# Android Debugging With Genymotion

## Scope

Use Genymotion for interactive Android device debugging and manual smoke tests.
This is an approved exception for emulator interactions; it does not replace the
Docker-first requirement for builds, dependency management, and automated tests.

## Local Environment

- This workstation uses Genymotion as its Android emulator.
- `adb` may not be available on the shell `PATH`; use the Android SDK or
   Genymotion-provided `adb` by absolute path when discovering devices, installing
   APKs, and launching activities.
- The local Genymotion ADB is
   `/Applications/Genymotion.app/Contents/MacOS/player.app/Contents/MacOS/tools/adb`.
- The active Genymotion Phone ARM64 device forwards ADB at `127.0.0.1:6555`.

## Procedure

1. Start the required Genymotion virtual device.
2. Prepare the stable local signing files. `android/app/build.gradle.kts` loads
   `android/key.properties`, while its `storeFile` is resolved relative to the
   `android/app/` module. Link both ignored files from `build/android-key/`
   without printing or committing their contents:

   ```sh
   ln -sfn ../build/android-key/key.properties android/key.properties
   ln -sfn ../../build/android-key/key.jks android/app/key.jks
   ```

   The Gradle configuration applies this signing config to all build types,
   including debug. This keeps local Docker-built APKs consistently signed and
   installable as updates on the emulator.
3. Use the Android debug entry points from the repository root:

   ```sh
   # Build a debug APK and install it to Genymotion.
   tool/android_debug_install.sh

   # Start a background debug session that builds, installs, and enables Dart hot reload.
   tool/android_hot_reload_start.sh

   # After saving Dart changes, request one hot reload from the running session.
   tool/android_hot_reload_trigger.sh

   # After development is complete, end its hot-reload session and pause the container.
   tool/android_dev_container_pause.sh

   # Before development resumes, unpause, restart, or recreate the container.
   tool/android_dev_container_resume.sh
   ```

   The Android entry points reuse the `piliplus-android-dev` Docker container,
   preserving its Gradle daemon across invocations. Set
   `PILIPLUS_ANDROID_DEV_CONTAINER` to use a different container name. The
   hot-reload start script returns after creating its background session.
   Follow `build/android-hot-reload/flutter-run.log` until it contains `Flutter
   run key commands`, then invoke the trigger script after each saved Dart
   change. The trigger sends Flutter's `r` command through a container-local
   FIFO. The session runs both ADB and `flutter run` inside Docker, keeping VM
   Service port forwarding and the control channel in the same network namespace. Set
   `PILIPLUS_ANDROID_DEVICE` to select a different ADB endpoint. Native Android,
   Gradle, manifest, dependency, and icon changes require a new session or a
   normal debug build.

   The Docker wrapper persists the Flutter 3.44.8 SDK, Pub packages, Gradle
   cache, and Android SDK under `build/docker-cache/`. The first invocation
   populates the cache; later builds reuse it. Set `PILIPLUS_DOCKER_CACHE` to use
   a different cache location. Remove the reusable development container with
   `docker rm -f piliplus-android-dev` when its caches or Flutter version need a
   fresh process.

   The pause entry point terminates the active `flutter run` session before
   freezing the development container. After resuming, start a fresh session
   with `tool/android_hot_reload_start.sh` before triggering reloads. On this
   OrbStack workstation, pausing the container can reclaim its inactive memory.
   The resume entry point starts a stopped container and recreates a removed
   container; the normal debug and hot-reload entry points also recreate it
   automatically.
4. Confirm the device is visible to ADB, then install the artifact and perform
   the requested interactive debugging or smoke test.
5. When debugging supports a code change, record only the relevant command and
   smoke-test outcome in the affected `skills/changes/` record. Keep device
   profiles, ADB endpoints, signing setup, installation details, and retry logs
   in this workflow or Git history unless a persistent device-specific issue
   makes them necessary to reproduce the behavior.

## Guardrails

- Do not use host Flutter, Gradle, or dependency commands as a substitute for
  the Docker workflow.
- Use `tool/docker_flutter.sh` for Flutter, Dart, Gradle, and launcher-icon
   generation commands so dependency downloads remain cached under `build/`.
- Treat `build/android-key/key.properties` and `build/android-key/key.jks` as
   local secrets. Never read them into chat, print passwords, or add either file
   or the ignored `android/key.properties` and `android/app/key.jks` links to
   Git.
- Use `tool/generate_android_launcher_icons.sh` after changing the active icon
   SVG. It regenerates the master and transparent foreground images, runs
   `flutter_launcher_icons`, then restores direct adaptive drawable references
   so the generator's `16%` inset does not double-apply the foreground safe area.
- Treat the emulator as disposable test state; do not rely on persistent data
  without documenting it.
- Flutter, Gradle, dependency resolution, compilation, and installation remain
   inside Docker.
- Keep `piliplus-android-dev` running during an active development conversation
   so its Gradle daemon remains warm. Do not pause it automatically after a
   build, install, or hot reload. Pause it only when the user explicitly asks or
   confirms that Android development is complete; resume it before the next
   Android debug action.