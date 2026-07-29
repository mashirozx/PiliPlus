# Video Detail Loading Skeleton

## Status

Active

## Scope

- Affected paths: `lib/pages/video/introduction/ugc/view.dart`
- Upstream relationship: upstream-compatible

## Intent

Keep the UGC video details page visually stable while author and video-detail data is loading.

## Implementation

- The UGC introduction displays animated skeletons for the author row, video metadata below the title, and action controls while the video detail has no BVID.
- The title remains on its existing loading path; loaded author, metadata, and action widgets are unchanged.
- The horizontal author row includes the action-control skeleton because that layout renders both areas together.

## Validation

- Docker: `tool/docker_flutter.sh flutter analyze lib/pages/video/introduction/ugc/view.dart` completed with no issues.
- Docker: `tool/docker_flutter.sh flutter build apk --debug --pub` built the debug APK successfully; it installed and launched on the Genymotion emulator.

## Follow-up

None.