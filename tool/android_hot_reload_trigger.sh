#!/usr/bin/env sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
container_name=${PILIPLUS_ANDROID_DEV_CONTAINER:-piliplus-android-dev}
state_dir="$repo_root/build/android-hot-reload"
control_path=/tmp/piliplus-hot-reload-control
pid_file="$state_dir/pid"

if [ ! -f "$pid_file" ]; then
  printf '%s\n' "No hot-reload session is running. Start one with tool/android_hot_reload_start.sh." >&2
  exit 1
fi

session_pid=$(cat "$pid_file")
if ! kill -0 "$session_pid" 2>/dev/null; then
  rm -f "$pid_file"
  printf '%s\n' "The previous hot-reload session has stopped. Start a new one with tool/android_hot_reload_start.sh." >&2
  exit 1
fi

docker exec "$container_name" sh -lc 'printf "r\n" > "$1"' sh "$control_path"
printf '%s\n' "Requested hot reload."