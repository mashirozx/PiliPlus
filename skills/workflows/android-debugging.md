# Android Debugging With Genymotion

## Scope

Use Genymotion for interactive Android device debugging and manual smoke tests.
This is an approved exception for emulator interactions; it does not replace the
Docker-first requirement for builds, dependency management, and automated tests.

## Procedure

1. Start the required Genymotion virtual device.
2. Build the Android artifact through the cached repository Docker workflow:

   ```sh
   tool/docker_flutter.sh flutter pub get
   tool/generate_android_launcher_icons.sh
   tool/docker_flutter.sh flutter build apk --debug --pub
   ```

   The wrapper persists the Flutter 3.44.8 SDK, Pub packages, Gradle cache, and
   Android SDK under `build/docker-cache/`. The first invocation populates the
   cache; later builds reuse it. Set `PILIPLUS_DOCKER_CACHE` to use a different
   cache location.
3. Confirm the device is visible to ADB, then install the artifact and perform
   the requested interactive debugging or smoke test.
4. Record the device profile, artifact, checks performed, and outcome in the
   relevant `skills/changes/` record when the debugging supports a code change.

## Guardrails

- Do not use host Flutter, Gradle, or dependency commands as a substitute for
  the Docker workflow.
- Use `tool/docker_flutter.sh` for Flutter, Dart, Gradle, and launcher-icon
   generation commands so dependency downloads remain cached under `build/`.
- Use `tool/generate_android_launcher_icons.sh` after changing the active icon
   SVG. It regenerates the master and transparent foreground images, runs
   `flutter_launcher_icons`, then restores direct adaptive drawable references
   so the generator's `16%` inset does not double-apply the foreground safe area.
- Treat the emulator as disposable test state; do not rely on persistent data
  without documenting it.