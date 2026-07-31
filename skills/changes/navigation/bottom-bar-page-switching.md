# Bottom Bar Page Switching

## Status

Active

## Scope

- Affected paths: `lib/pages/main/controller.dart`, `lib/pages/main/view.dart`,
  `lib/common/widgets/floating_navigation_bar.dart`, and
  `lib/common/widgets/flutter/tabs.dart`.
- Upstream relationship: upstream-compatible.

## Intent

Let users switch adjacent main destinations by swiping the bottom bar or tablet
sidebar, with an animated selected-item background.

## Implementation

- The floating and default Material 3 navigation bars use one shared
  indicator. It expands from the previous item toward the target during the
  first half of the transition, then contracts from the old side during the
  second half. The Material 3 bar retains Flutter's native size, safe-area,
  labels, icons, and destination semantics while its built-in indicator is
  transparent.
- A horizontal bottom-bar swipe on either style selects only the adjacent
  destination; it does nothing beyond the first or last destination.
- In tablet sidebar mode, the `NavigationDrawer` measures its direct
  destination children so its shared indicator expands and contracts
  vertically, and an upward or downward swipe on the sidebar selects an
  adjacent destination.

## Validation

- `tool/docker_flutter.sh flutter analyze lib/pages/main/controller.dart
  lib/pages/main/view.dart lib/common/widgets/floating_navigation_bar.dart
  lib/common/widgets/flutter/tabs.dart` completed without issues.
- A Genymotion session started through `tool/android_hot_reload_start.sh` and
  reloaded through `tool/android_hot_reload_trigger.sh` successfully switched
  from dynamics to mine with a left bottom-bar swipe, then returned with a
  right swipe.
- The non-floating Material 3 bar was rebuilt and verified on Genymotion with
  its native height and safe-area layout preserved. Its shared indicator
  expanded from dynamics toward mine, then settled as a single mine pill.
- A debug APK installed on the Genymotion tablet verified upward sidebar swipes
  from home to dynamics and dynamics to mine, including the vertical shared
  indicator transition and settled target state. Existing page-transition
  behavior was left unchanged.

## Follow-up

None.