#!/usr/bin/env sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

"$repo_root/tool/generate_logo_png.sh"
"$repo_root/tool/docker_flutter.sh" dart run flutter_launcher_icons

cat > "$repo_root/android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
  <background android:drawable="@color/ic_launcher_background"/>
  <foreground android:drawable="@drawable/ic_launcher_foreground"/>
  <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>
</adaptive-icon>
EOF

for colors_file in \
  "$repo_root/android/app/src/main/res/values-v31/colors.xml" \
  "$repo_root/android/app/src/main/res/values-night-v31/colors.xml"; do
  sed -i.bak 's|<color name="ic_launcher_background">.*</color>|<color name="ic_launcher_background">#121212</color>|' "$colors_file"
  rm "$colors_file.bak"
done