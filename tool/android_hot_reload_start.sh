#!/usr/bin/env sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
device=${PILIPLUS_ANDROID_DEVICE:-host.docker.internal:6555}
container_name=${PILIPLUS_ANDROID_DEV_CONTAINER:-piliplus-android-dev}
state_dir="$repo_root/build/android-hot-reload"
control_path=/tmp/piliplus-hot-reload-control
log_file="$state_dir/flutter-run.log"
pid_file="$state_dir/pid"

if [ -f "$pid_file" ]; then
  session_pid=$(cat "$pid_file")
  if kill -0 "$session_pid" 2>/dev/null; then
    printf '%s\n' "A hot-reload session is already running (PID $session_pid)." >&2
    printf '%s\n' "Use tool/android_hot_reload_trigger.sh after saving Dart changes." >&2
    exit 1
  fi
fi

mkdir -p "$state_dir"
rm -f "$pid_file"

PILIPLUS_DOCKER_CONTAINER="$container_name" "$repo_root/tool/docker_flutter.sh" sh -lc '
  control_path=$1
  device=$2
  rm -f "$control_path"
  mkfifo "$control_path"
  adb connect "$device" >/dev/null
  pwsh -NoLogo -NoProfile -File lib/scripts/patch.ps1 android
  tail -f "$control_path" | flutter run -d "$device"
' sh "$control_path" "$device" >"$log_file" 2>&1 &

session_pid=$!
printf '%s\n' "$session_pid" > "$pid_file"

printf '%s\n' "Starting hot-reload session (PID $session_pid)."
printf '%s\n' "Logs: build/android-hot-reload/flutter-run.log"
printf '%s\n' "After Flutter is ready, save Dart changes and run: tool/android_hot_reload_trigger.sh"