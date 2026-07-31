# Fork Change Records

Record every fork-specific feature, fix, configuration, dependency, build, or
tooling change here. Use the template in `../maintenance/knowledge-base.md`.

When records become numerous, group them by affected area, such as `player/`,
`platform/`, or `build/`. Keep each record focused on one maintainable behavior
or change set.

## Platform Records

- `platform/branding-and-identity.md`: fork application identity, display
	naming, SVG-derived icons, and cross-platform conflict anchors.
- `platform/android-launcher-resource-cycle.md`: adaptive icon resource-cycle
	avoidance and safe-area regeneration rules.
- `platform/linux-package-executable.md`: Linux executable naming and the
	`piliplus` compatibility command used by package formats.
- `android-debug-entrypoints.md`: Docker-first debug installation and on-demand
  Android hot-reload entry points.

## Automation Records

- `release-build-dispatch-on-push.md`: dispatch the full tagged Build workflow
	after every `release` push.
- `release-changelog.md`: populate tagged GitHub Release notes from patch-based
	differences with the previous release.
- `upstream-rebase-automation.md`: guarded hourly GH-AW/Copilot synchronization
  of this fork with its upstream repository.

## Update Records

- `update-release-markdown.md`: render Markdown release notes in the in-app
	update dialog and open their links externally.

## Video Records

- `video/video-detail-loading-skeleton.md`: loading placeholders that stabilize
	UGC video detail metadata and controls.