#!/usr/bin/env sh

set -eu

if [ "$#" -eq 0 ]; then
  printf '%s\n' "Usage: tool/docker_flutter.sh <command> [arguments...]" >&2
  exit 64
fi

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cache_root=${PILIPLUS_DOCKER_CACHE:-"$repo_root/build/docker-cache"}
flutter_version=3.47.2
flutter_cache="$cache_root/flutter-$flutter_version-sdk"
container_name=${PILIPLUS_DOCKER_CONTAINER:-}
docker_tty_args=

if [ -t 0 ] && [ -t 1 ]; then
  docker_tty_args=-it
fi

mkdir -p \
  "$flutter_cache" \
  "$cache_root/pub" \
  "$cache_root/gradle" \
  "$cache_root/android-sdk"

if [ -n "$container_name" ]; then
  if ! docker container inspect --format '{{.State.Running}}' "$container_name" 2>/dev/null | grep -qx true; then
    if docker container inspect "$container_name" >/dev/null 2>&1; then
      docker start "$container_name" >/dev/null
    else
      docker run -d --name "$container_name" --platform linux/amd64 \
        -v "$repo_root":/workspace \
        -v "$flutter_cache":/cache/flutter \
        -v "$cache_root/pub":/cache/pub \
        -v "$cache_root/gradle":/cache/gradle \
        -v "$cache_root/android-sdk":/cache/android-sdk \
        -w /workspace \
        ghcr.io/cirruslabs/flutter:stable \
        sh -lc '
          set -eu

          if [ ! -d /cache/flutter/.git ]; then
            git clone --depth=1 --branch 3.47.2 https://github.com/flutter/flutter.git /cache/flutter
          fi

          if ! git -C /cache/flutter rev-parse -q --verify refs/tags/3.47.2 >/dev/null; then
            git -C /cache/flutter fetch --depth=1 origin 3.47.2
            git -C /cache/flutter tag -f 3.47.2 FETCH_HEAD
          fi
          git -C /cache/flutter checkout --detach 3.47.2

          if [ ! -d /cache/android-sdk/platform-tools ]; then
            cp -a "${ANDROID_HOME:-/opt/android-sdk}"/. /cache/android-sdk/
          fi

          exec tail -f /dev/null
        ' >/dev/null
    fi
  fi

  if ! docker exec "$container_name" sh -c 'command -v pwsh' >/dev/null 2>&1; then
    docker exec "$container_name" sh -lc '
      set -eu
      apt-get update
      apt-get install -y wget
      wget -q https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb
      dpkg -i /tmp/packages-microsoft-prod.deb
      rm /tmp/packages-microsoft-prod.deb
      apt-get update
      apt-get install -y powershell
    '
  fi

  exec docker exec $docker_tty_args \
    -w /workspace \
    -e FLUTTER_ROOT=/cache/flutter \
    -e GITHUB_WORKSPACE=/workspace \
    -e PATH=/cache/flutter/bin:/cache/android-sdk/platform-tools:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    -e PUB_CACHE=/cache/pub \
    -e GRADLE_USER_HOME=/cache/gradle \
    -e ANDROID_HOME=/cache/android-sdk \
    -e ANDROID_SDK_ROOT=/cache/android-sdk \
    "$container_name" \
    sh -lc 'exec "$@"' docker_flutter "$@"
fi

docker run --rm --platform linux/amd64 $docker_tty_args \
  -v "$repo_root":/workspace \
  -v "$flutter_cache":/cache/flutter \
  -v "$cache_root/pub":/cache/pub \
  -v "$cache_root/gradle":/cache/gradle \
  -v "$cache_root/android-sdk":/cache/android-sdk \
  -w /workspace \
  ghcr.io/cirruslabs/flutter:stable \
  sh -lc '
    set -eu

    if [ ! -d /cache/flutter/.git ]; then
      git clone --depth=1 --branch 3.47.2 https://github.com/flutter/flutter.git /cache/flutter
    fi

    if ! git -C /cache/flutter rev-parse -q --verify refs/tags/3.47.2 >/dev/null; then
      git -C /cache/flutter fetch --depth=1 origin 3.47.2
      git -C /cache/flutter tag -f 3.47.2 FETCH_HEAD
    fi
    git -C /cache/flutter checkout --detach 3.47.2

    if [ ! -d /cache/android-sdk/platform-tools ]; then
      cp -a "${ANDROID_HOME:-/opt/android-sdk}"/. /cache/android-sdk/
    fi

    export PATH=/cache/flutter/bin:$PATH
    export PUB_CACHE=/cache/pub
    export GRADLE_USER_HOME=/cache/gradle
    export ANDROID_HOME=/cache/android-sdk
    export ANDROID_SDK_ROOT=/cache/android-sdk

    exec "$@"
  ' docker_flutter "$@"