# Video Coin Action SVG Icon

## Status

Active

## Scope

- Affected paths: `assets/images/coin_action.svg`, `assets/images/coin_action_unselected.svg`, `lib/common/assets.dart`, `lib/common/widgets/svg/coin_icon.dart`, and video action controls.
- Upstream relationship: upstream-compatible.

## Intent

Replace the Font Awesome `B` glyph used for the video coin action with supplied selected and unselected coin SVGs.

## Implementation

- `coin_action.svg` is the selected icon and `coin_action_unselected.svg` is the unselected icon. Both remove source XML/DTD metadata, editor attributes, fixed dimensions, and hard-coded fills while retaining their `viewBox` and paths.
- `CoinIcon` owns SVG asset selection, dimensions, `srcIn` coloring, and the
    coin accessibility label. It renders the selected SVG at `18px` and the
    unselected SVG at `20px` so their visible bounds align with neighboring action
    icons.
- `ActionItem.iconBuilder` and `selectIconBuilder` supply the current action
    color to non-`Icon` renderers without changing existing `Icon` behavior. UGC
    and PGC pass the calculated action color to both states; the player header
    fixes the unselected icon to white and passes the selected theme color through.

## Validation

- Docker: `tool/docker_flutter.sh flutter build apk --debug --pub` passed after
    restoring the UGC `Assets` import required by the fork's AI action. The APK
    installed and launched as `eu.mashiro.bilibili.pro.debug` on Genymotion Phone
    ARM64 at `127.0.0.1:6555`.
- `git diff --check` passed after applying the shared component to `main`.
- Editor diagnostics reported no errors for `CoinIcon`, the three coin action
    call sites, and `ActionItem`.
- Docker: `tool/docker_flutter.sh dart format lib/common/assets.dart lib/pages/video/introduction/ugc/widgets/action_item.dart lib/pages/video/introduction/ugc/view.dart lib/pages/video/introduction/pgc/view.dart lib/pages/video/widgets/header_control.dart` completed, and the targeted `flutter analyze` passed.
- Docker: `tool/docker_flutter.sh flutter build bundle` passed and packaged the SVG asset.
- Docker and Genymotion: built `build/app/outputs/flutter-apk/app-debug.apk`,
  then installed and launched `eu.mashiro.bilibili.pro.debug` on the active
  `motion_phone_arm64` device at `127.0.0.1:6555`. The prior debug package was
  uninstalled first because its signing certificate did not match the Docker-built APK.
- Docker and Genymotion: rebuilt the debug APK after adjusting the unselected
    icon to `20px`, then reinstalled and launched it on the same device. The
    Docker debug signing certificate again differed from the installed package, so
    the emulator package was uninstalled before installation.
- Docker and Genymotion: linked the ignored local signing files as
    `android/key.properties` and `android/app/key.jks`, rebuilt the debug APK,
    and updated the existing emulator package successfully with `adb install -r`.

## Follow-up

None.