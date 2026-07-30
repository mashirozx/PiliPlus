#!/usr/bin/env sh

set -eu

if [ "$#" -eq 0 ]; then
  printf '%s\n' "Usage: tool/docker_flutter.sh <command> [arguments...]" >&2
  exit 64
fi

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cache_root=${PILIPLUS_DOCKER_CACHE:-"$repo_root/build/docker-cache"}

mkdir -p \
  "$cache_root/flutter" \
  "$cache_root/pub" \
  "$cache_root/gradle" \
  "$cache_root/android-sdk"

docker run --rm --platform linux/amd64 \
  -v "$repo_root":/workspace \
  -v "$cache_root/flutter":/cache/flutter \
  -v "$cache_root/pub":/cache/pub \
  -v "$cache_root/gradle":/cache/gradle \
  -v "$cache_root/android-sdk":/cache/android-sdk \
  -w /workspace \
  ghcr.io/cirruslabs/flutter:stable \
  sh -lc '
    set -eu

    if [ ! -d /cache/flutter/.git ]; then
      cp -a /sdks/flutter/. /cache/flutter/
    fi

    if ! git -C /cache/flutter rev-parse -q --verify refs/tags/3.44.8 >/dev/null; then
      git -C /cache/flutter fetch --depth=1 origin 3.44.8
      git -C /cache/flutter tag -f 3.44.8 FETCH_HEAD
    fi
    git -C /cache/flutter checkout --detach 3.44.8

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