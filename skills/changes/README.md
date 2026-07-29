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

## Automation Records

- `upstream-rebase-automation.md`: guarded hourly GH-AW/Copilot synchronization
  of this fork with its upstream repository.

## Video Records

- `video/video-detail-loading-skeleton.md`: loading placeholders that stabilize
	UGC video detail metadata and controls.