#!/usr/bin/env sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
container_name=${PILIPLUS_ANDROID_DEV_CONTAINER:-piliplus-android-dev}

if ! container_state=$(docker container inspect --format '{{.State.Status}}' "$container_name" 2>/dev/null); then
  PILIPLUS_DOCKER_CONTAINER="$container_name" "$repo_root/tool/docker_flutter.sh" true
  printf '%s\n' "Recreated $container_name. Start a debug or hot-reload session when ready."
  exit 0
fi

case "$container_state" in
  paused)
    docker unpause "$container_name" >/dev/null
    printf '%s\n' "Resumed $container_name. Start a new hot-reload session when ready."
    ;;
  exited|created)
    docker start "$container_name" >/dev/null
    printf '%s\n' "Started $container_name. Start a new hot-reload session when ready."
    ;;
  running)
    printf '%s\n' "$container_name is already running."
    ;;
  *)
    printf '%s\n' "The development container is $container_state; it cannot be resumed." >&2
    exit 1
    ;;
esac