# Android Document Provider Build

## Status

Active

## Scope

- Affected paths: `android/app/src/main/java/com/example/piliplus/AndroidHelper.java`.
- Upstream relationship: upstream-compatible.

## Intent

Allow the Android app to compile when Java and Kotlin sources are compiled in
separate task phases.

## Implementation

`AndroidHelper.updateDocProvider` creates the manifest-declared
`BiliDocumentsProvider` component from its fully qualified class name instead
of a direct Java reference to the Kotlin type. The provider and its enabled
state remain unchanged.

## Validation

- The Docker Android debug build completed and produced
  `build/app/outputs/flutter-apk/app-debug.apk`.
- The APK installed and launched successfully on Genymotion.

## Follow-up

None.