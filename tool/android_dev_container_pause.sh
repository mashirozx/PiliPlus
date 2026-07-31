#!/usr/bin/env sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
container_name=${PILIPLUS_ANDROID_DEV_CONTAINER:-piliplus-android-dev}
state_dir="$repo_root/build/android-hot-reload"
pid_file="$state_dir/pid"

if ! container_state=$(docker container inspect --format '{{.State.Status}}' "$container_name" 2>/dev/null); then
  printf '%s\n' "The development container does not exist. A debug or hot-reload entrypoint will recreate it." >&2
  exit 0
fi

case "$container_state" in
  paused)
    printf '%s\n' "The development container is already paused."
    exit 0
    ;;
  exited|created)
    printf '%s\n' "The development container is already stopped. Use tool/android_dev_container_resume.sh to start it."
    exit 0
    ;;
  running)
    ;;
  *)
    printf '%s\n' "The development container is $container_state; it cannot be paused." >&2
    exit 1
    ;;
esac

if [ -f "$pid_file" ]; then
  session_pid=$(cat "$pid_file")
  if kill -0 "$session_pid" 2>/dev/null; then
    docker exec "$container_name" sh -lc 'pkill -f "/tmp/piliplus-hot-reload-control" || true'
    kill "$session_pid" 2>/dev/null || true
    printf '%s\n' "Stopped the active Flutter hot-reload session."
  fi
  rm -f "$pid_file"
fi

docker pause "$container_name" >/dev/null
printf '%s\n' "Paused $container_name."
printf '%s\n' "OrbStack can reclaim memory from the paused development container."