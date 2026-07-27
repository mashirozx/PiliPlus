# Android Debugging With Genymotion

## Scope

Use Genymotion for interactive Android device debugging and manual smoke tests.
This is an approved exception for emulator interactions; it does not replace the
Docker-first requirement for builds, dependency management, and automated tests.

## Procedure

1. Start the required Genymotion virtual device.
2. Build the Android artifact through the repository's Docker workflow.
3. Confirm the device is visible to ADB, then install the artifact and perform
   the requested interactive debugging or smoke test.
4. Record the device profile, artifact, checks performed, and outcome in the
   relevant `skills/changes/` record when the debugging supports a code change.

## Guardrails

- Do not use host Flutter, Gradle, or dependency commands as a substitute for
  the Docker workflow.
- Treat the emulator as disposable test state; do not rely on persistent data
  without documenting it.