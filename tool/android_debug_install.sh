#!/usr/bin/env sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
device=${PILIPLUS_ANDROID_DEVICE:-host.docker.internal:6555}
container_name=${PILIPLUS_ANDROID_DEV_CONTAINER:-piliplus-android-dev}

PILIPLUS_DOCKER_CONTAINER="$container_name" "$repo_root/tool/docker_flutter.sh" sh -lc '
  device=$1
  adb connect "$device" >/dev/null
  pwsh -NoLogo -NoProfile -File lib/scripts/patch.ps1 android
  flutter build apk --debug --pub
  adb -s "$device" install -r build/app/outputs/flutter-apk/app-debug.apk
' sh "$device"