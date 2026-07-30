# Linux Package Executable Identity

## Status

Active

## Scope

- Affected paths: `linux/CMakeLists.txt`, `.github/workflows/linux_x64.yml`,
  `assets/linux/DEBIAN/postinst`, `assets/linux/DEBIAN/prerm`, and
  `assets/linux/DEBIAN/postrm`.
- Upstream relationship: fork-only.

## Intent

Package the renamed Linux executable without breaking users and scripts that
still invoke `piliplus`.

## Implementation

- CMake produces the executable `bilibili_pro`.
- DEB, RPM, and AppImage packaging must reference `bilibili_pro` for the
  bundled executable, checksum, permissions, process termination, and AppRun.
- Keep `/usr/bin/piliplus` as a compatibility symlink to
  `/opt/PiliPlus/bilibili_pro`; desktop-entry `Exec=piliplus` remains valid.
- Package metadata and artifact filenames may retain `PiliPlus` or `piliplus`
  where they identify compatibility-facing formats rather than the executable.

## Validation

- Static inspection confirmed the release workflow uses `BINARY_NAME` for DEB,
  RPM, and AppImage executable operations.
- DEB lifecycle scripts recreate, remove, and terminate the renamed executable
  through the compatibility command as appropriate.

## Rebase Resolution

When upstream changes Linux CMake or release packaging, preserve the executable
name `bilibili_pro` at every on-disk execution point. Preserve the
`/usr/bin/piliplus` symlink and desktop `Exec=piliplus` compatibility boundary;
do not rename those interfaces merely to match the executable. Validate the
combined result by tracing the executable path through CMake, each workflow
package step, and the Debian lifecycle scripts.

## Follow-up

Run the Linux Docker packaging path before distributing release artifacts.