#!/usr/bin/env sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

docker run --rm --platform linux/amd64 \
  -v "$repo_root":/workspace \
  -w /workspace \
  --entrypoint sh \
  dpokidov/imagemagick:7.1.1-47 \
  -c '
    set -eu
    rm -f assets/images/logo/bilibili_pro_icon*.svg
    render_logo() {
      size="$1"
      output="$2"
      radius=$((size * 18 / 100))
      edge=$((size - 1))

      magick -size "${size}x${size}" xc:none \
        -fill "#121212" \
        -draw "roundrectangle 0,0 ${edge},${edge} ${radius},${radius}" \
        \( -background none assets/images/logo/bilibili.champagne-swapped.svg \
          -resize "${size}x${size}" \) \
        -compose over -composite "$output"
    }

    render_logo 512 assets/images/logo/logo.png
    render_logo 512 assets/images/logo/desktop/logo_large.png
    render_logo 1024 /tmp/bilibili_logo_master.png
    magick /tmp/bilibili_logo_master.png \
      -define icon:auto-resize=16,24,32,48,64,72,96,128,256 \
      assets/images/logo/ico/app_icon.ico

    magick -size 1024x1024 xc:"#121212" \
      \( -background none assets/images/logo/bilibili.champagne-swapped.svg \
        -resize 1024x1024 \) \
      -compose over -composite assets/images/logo/bilibili_pro_icon.png

    magick -background none assets/images/logo/bilibili.champagne-swapped.svg \
      -resize 630x630 +repage -gravity center -extent 1024x1024 \
      assets/images/logo/bilibili_pro_icon_foreground.png
  '