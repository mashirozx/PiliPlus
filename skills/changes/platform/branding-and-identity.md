# Fork Branding and Application Identity

## Status

Active

## Scope

- Affected paths: `android/`, `ios/`, `macos/`, `linux/`, `windows/`,
  `assets/images/logo/`, and `pubspec.yaml`.
- Upstream relationship: fork-only.

## Intent

Allow this fork to install alongside the upstream application while using the
requested icon and visible name.

## Implementation

- The Android application ID and namespace, Apple bundle identifiers, and Linux
  GTK application ID are `eu.mashiro.bilibili.pro`.
- Windows uses a distinct executable name and installer AppId.
- The visible application name is `哔哩哔哩` on every platform, including Android
  debug and development variants. Their application ID suffixes remain distinct.
- The shared runtime `Constants.appName` is `哔哩哔哩 Pro`, which controls the
  About-page label, window and tray titles, user-facing prompts, and names used
  for locally created files and directories.
- `Constants.sourceCodeUrl` and the GitHub release API point to
  `mashirozx/PiliPlus`, so in-app source links and update checks target this
  fork. The Debian package homepage and README repository badges use the same
  URL; upstream remains the Git remote used only for rebase synchronization.
- README display-name text uses `哔哩哔哩(゜-゜)つロ干杯~-`; its repository URLs
  retain `mashirozx/PiliPlus` because that is the fork's actual GitHub path.
- The README Latest Release badge reads the latest published release tag from
  the fork and links to its Releases page; it is independent of Build workflow
  status.
- The README Build badge uses the Shields workflow-status endpoint without a
  `branch=main` filter because this workflow runs through pull requests and
  manual dispatch rather than `push` on `main`. Link it to the GitHub Actions
  workflow page.
- The About page subtitle is `哔哩哔哩(゜-゜)つロ干杯~-`; its accessibility label
  remains the existing descriptive Chinese text.
- macOS uses `bilibili.pro.app` for the Xcode product reference and shared
  scheme buildable name. `PRODUCT_NAME` is `bilibili.pro`, while
  `PRODUCT_DISPLAY_NAME` remains `哔哩哔哩` for `CFBundleName`; this keeps the
  bundle path ASCII and compatible with Xcode 26 without changing the visible
  app name. The macOS release workflow passes this bundle path to `create-dmg`
  with `--no-code-sign`, because hosted GitHub Actions runners do not provide a
  signing identity. It renames its single generated DMG without assuming a
  display-name-derived filename to the `bilibili.pro_macos_<version>.dmg`
  release artifact name.
- Android JNI bindings and the jnigen source configuration reference
  `eu.mashiro.bilibili.pro.AndroidHelper`. The notification channel uses the
  same application identity. This prevents a startup-time
  `ClassNotFoundException` that otherwise occurs before `runApp` and leaves the
  first frame unrendered.
- `bilibili.svg` and the `bilibili.*.svg` files in `assets/images/logo/` are
  design sources and must be retained. `bilibili.champagne-swapped.svg` is the
  active square-icon source; its `#121212` base fills standard icon canvases
  while the muted `#3A3833` television and champagne lettering remain centered.
- `bilibili.champagne.svg` remains a selectable design variant and does not
  drive generated platform icons.
- The PNG master and all platform icon variants are generated from the active
  SVG with `dpokidov/imagemagick:7.1.1-47`, mounting the repository at
  `/workspace` and running `magick` resize and ICO conversion commands from
  that directory.
- `desktop/logo_large.png`, `ico/app_icon.ico`, and `logo.png` are `512px`
  rounded-corner renders of `bilibili.champagne-swapped.svg`. `logo_2.png` is the
  aspect-ratio-preserving `512x234` PNG render of `bilibili.logo.svg`.
- Run `tool/generate_logo_png.sh` to regenerate `logo.png`. It runs
  ImageMagick in Docker and first removes obsolete
  `bilibili_pro_icon*.svg` generation intermediates; those files are never
  design sources and must not be retained. ImageMagick does not render the
  source SVG's leading relative move correctly, so the script explicitly
  composes the same `#121212` 18%-radius rounded background before overlaying
  the SVG artwork. It applies this process to `logo.png`, `logo_large.png`, and
  `app_icon.ico`.
- Android uses the `#121212` adaptive background and a separate transparent
  foreground PNG containing the centered core artwork. Its `630px` render size
  matches the visual scale of the system Bilibili app icon while retaining
  transparent safety padding. Do not add an XML inset: the foreground asset
  already contains the required safe area.
  `flutter_launcher_icons` regenerates a `16%` inset, so restore the direct
  foreground and monochrome drawable references in `ic_launcher.xml` after
  running it. `values-v31` and `values-night-v31` must also keep
  `ic_launcher_background` at `#121212`; system dynamic-color references cause
  Android 12+ launchers to render an unintended theme-colored icon background.
- Run `tool/generate_android_launcher_icons.sh` whenever the active icon source
  changes. It regenerates the standard image and transparent foreground,
  invokes `flutter_launcher_icons` through the cached Docker wrapper, and
  restores the direct adaptive drawable references. When choosing a new source
  icon, update the standard-image background in `generate_logo_png.sh` and
  `adaptive_icon_background` in `pubspec.yaml`, plus both Android 12 color
  qualifiers, to the same intended color.
- Linux installs the desktop entry and hicolor icon with the new application
  ID.
- The Android release workflow renames split APKs as
  `BilibiliPro_android_<semantic-version>+<timestamp>_<abi>.apk`. It removes the
  build version's short commit hash only when renaming release attachments;
  release uploads and all three ABI artifact globs use this exact prefix. Retain
  the ABI suffixes because the in-app update downloader selects Android assets
  by ABI substring.
- The iOS, Linux, and Windows release workflows retain their existing package
  commands, then rename the finished IPA, Linux packages, portable ZIP, and
  Windows setup executable from `PiliPlus_` to `BilibiliPro_` before release and
  artifact upload.
- The Linux release workflow packages the CMake `bilibili_pro` executable in
  deb, RPM, and AppImage artifacts. Deb and RPM retain `/usr/bin/piliplus` as
  a compatibility symlink.

## Validation

- Docker: parsed Android XML and iOS plist; verified Android Gradle,
  manifest, and source package identifiers agree.
- Docker: generated and inspected Android, iOS, macOS, Windows, and Linux icon
  resources with `dpokidov/imagemagick:7.1.1-47`; the Windows ICO contains seven
  sizes and the Linux icon is `512x512`.
- Docker: regenerated all platform icon resources from
  `assets/images/logo/bilibili.champagne-swapped.svg`. The standard `1024x1024` PNG is
  fully square; the Android adaptive foreground has transparent edges and an
  approximately `53%`-wide centered silhouette on its `432px` density canvas.
  `:app:processDebugResources` passed.
- Docker: regenerated the Android density icons, iOS and macOS AppIcon sets,
  desktop PNGs, and Windows ICO from `bilibili.champagne-swapped.svg` through
  `tool/generate_android_launcher_icons.sh`; `:app:processDebugResources`
  succeeded with the generated resources.
- Docker and Genymotion: regenerated Android launcher resources with
  `tool/generate_android_launcher_icons.sh`; `:app:processDebugResources`
  succeeded through the cached Docker wrapper. The rebuilt debug APK replaced
  the incompatible-signature install on `127.0.0.1:6555` and launched
  `eu.mashiro.bilibili.pro.debug` successfully.
- Docker: regenerated the rounded desktop, ICO, and general logo assets from
  `bilibili.champagne-swapped.svg`, and the horizontal `logo_2.png` from
  `bilibili.logo.svg`; inspected dimensions and transparent corners.
- Docker: built `build/app/outputs/flutter-apk/app-debug.apk` with Flutter
  `3.44.8` in `ghcr.io/cirruslabs/flutter:stable` on `linux/amd64`. The build
  applies the Android Flutter patches from `lib/scripts/patch.ps1`; Gradle runs
  with one worker and extended network timeouts under OrbStack.
- Genymotion: installed the debug APK on `127.0.0.1:6555`
  (`motion_phone_arm64`). Android reports the package as
  `eu.mashiro.bilibili.pro.debug`; its launcher resolves to the new
  `eu.mashiro.bilibili.pro.MainActivity`, and the process started successfully.
- Docker and Genymotion: rebuilt and installed the debug APK after fixing the
  Android 12 `values-v31` and `values-night-v31` launcher-color overlays.
  The system App info page rendered the black-and-gold icon with its fixed
  `#121212` adaptive background rather than the device's pink dynamic accent.
- Genymotion: after a Docker `flutter clean` rebuild, the debug APK contains
  only the new JNI class path. The prior debug package was uninstalled because
  its Docker debug signature differed; the replacement installed successfully,
  rendered a Flutter frame, and produced neither the old AndroidHelper class
  error nor an unhandled Dart exception.
- Static: verified the Linux package workflow and deb lifecycle scripts use
  the CMake-defined `bilibili_pro` executable.
- Static: verified Android release asset renaming, release upload, and each
  split-ABI artifact upload use the `BilibiliPro_android` prefix.
- Docker: parsed `macos/Runner.xcodeproj` with `xcodeproj` in
  `ruby:3.4-alpine` after quoting the macOS product path.
- Static: verified the macOS release workflow packages `bilibili.pro.app` and
  disables DMG signing for unsigned CI releases, then requires exactly one
  generated DMG before applying the release artifact name.
- Static: verified `bilibili.champagne-swapped.svg` preserves the source paths
  and black fills while applying muted `#3A3833` television fills and
  `#C59F4E` lettering; it is the active source for all generated app icons.

## Rebase Resolution

- Treat this record as the source of truth when upstream changes application
  identity, display metadata, or generated launcher resources. Preserve the
  fork package and bundle identity `eu.mashiro.bilibili.pro`; do not restore
  `com.example.piliplus` or upstream `PiliPlus` identifiers during conflict
  resolution.
- For macOS conflicts, retain the split between ASCII
  `PRODUCT_NAME = bilibili.pro` and visible
  `PRODUCT_DISPLAY_NAME = 哔哩哔哩`. The Xcode product reference and every shared
  scheme `BuildableName` must remain `bilibili.pro.app`, while
  `CFBundleName` resolves `PRODUCT_DISPLAY_NAME`.
- For Android adaptive-icon conflicts, preserve `#121212` as the background,
  direct foreground and monochrome drawable references in
  `mipmap-anydpi-v26/ic_launcher.xml`, and the transparent safe-area foreground
  PNG. Regenerate binary density resources from the active SVG instead of
  attempting a binary merge.
- Keep generated platform icon binaries synchronized from
  `assets/images/logo/bilibili.champagne-swapped.svg`; use `bilibili.logo.svg` only for
  the aspect-ratio-preserving `logo_2.png`. The other `bilibili.*.svg` files are
  selectable design variants, not independently packaged assets. Delete only
  `bilibili_pro_icon*.svg` intermediate files when regenerating icons.

## Follow-up

Run the relevant Docker-based platform builds before distributing binaries.