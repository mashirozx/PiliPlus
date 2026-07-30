# Android Launcher Resource Cycle

## Status

Active

## Scope

- Affected paths: `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`,
  `android/app/src/main/res/drawable-*/ic_launcher_{foreground,monochrome}.png`,
  and `android/app/src/main/res/drawable-nodpi/ic_launcher_foreground.png`
- Upstream relationship: fork-only

## Intent

Avoid a resource cycle while keeping adaptive launcher artwork inside the safe
area required by launcher masks.

## Implementation

- Removed the self-referential XML drawable so adaptive icons resolve directly
	to generated foreground PNGs.
- The XML uses direct foreground and monochrome drawable references; it must
	not add a second inset because the source foreground bitmap already contains
	transparent safe-area padding. The active icon uses a `630px` foreground
	render on a `1024px` canvas to match the desired system-icon scale.
- `flutter_launcher_icons` regenerates density PNGs but rewrites a `16%` inset.
	Restore the direct references after running the generator.

## Validation

Docker Flutter 3.44.8 successfully ran
`./gradlew :app:processDebugResources --no-daemon` after the foreground and
monochrome resources were generated. The prior `ResourceCycle` diagnostic was
not reproduced.

## Rebase Resolution

If upstream modifies `ic_launcher.xml`, retain direct references to
`@drawable/ic_launcher_foreground` and `@drawable/ic_launcher_monochrome`.
Never restore the deleted self-referential
`drawable/ic_launcher_foreground.xml`; regenerate binary density resources from
the active SVG source instead of resolving image conflicts manually.

## Follow-up

Run the Docker resource task after resolving any Android launcher-resource
conflict.