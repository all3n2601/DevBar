#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
staging="$(mktemp -d)"
trap 'rm -rf "$staging"' EXIT
iconset="$staging/DevBar.iconset"
mkdir -p "$iconset" Resources
for size in 16 32 128 256 512; do
  sips -s format png -z "$size" "$size" docs/assets/devbar-logo.png --out "$iconset/icon_${size}x${size}.png" >/dev/null
  double=$((size * 2))
  sips -s format png -z "$double" "$double" docs/assets/devbar-logo.png --out "$iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$iconset" -o Resources/DevBar.icns
