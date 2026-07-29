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
3. Build the Android artifact through the cached repository Docker workflow:

   ```sh
   tool/docker_flutter.sh flutter pub get
   tool/generate_android_launcher_icons.sh
   tool/docker_flutter.sh flutter build apk --debug --pub
   ```

   The wrapper persists the Flutter 3.44.8 SDK, Pub packages, Gradle cache, and
   Android SDK under `build/docker-cache/`. The first invocation populates the
   cache; later builds reuse it. Set `PILIPLUS_DOCKER_CACHE` to use a different
   cache location.
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