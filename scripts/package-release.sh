#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
version="$(cat VERSION)"
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$ ]]; then
  echo 'VERSION must contain a semantic version.' >&2
  exit 1
fi
if ! /usr/bin/grep -Fq "\"$version\"" Sources/Core/Version.swift; then
  echo 'VERSION and Sources/Core/Version.swift disagree.' >&2
  exit 1
fi
if [[ "${GITHUB_REF_TYPE:-}" == "tag" && "${GITHUB_REF_NAME:-}" != "v$version" ]]; then
  echo 'Release tag must match VERSION.' >&2
  exit 1
fi
swift build -c release --arch arm64 --arch x86_64
binary_dir="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)"
output="$PWD/dist"
mkdir -p "$output"
staging="$(mktemp -d)"
trap 'rm -rf "$staging"' EXIT
app="$staging/DevBar.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$binary_dir/DevBar" "$app/Contents/MacOS/DevBar"
base_version="${version%%-*}"
cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>DevBar</string>
<key>CFBundleDisplayName</key><string>DevBar</string>
<key>CFBundleIdentifier</key><string>app.byallen.devbar</string>
<key>CFBundleExecutable</key><string>DevBar</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>$base_version</string>
<key>CFBundleVersion</key><string>$base_version</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
plutil -lint "$app/Contents/Info.plist"
architectures="$(lipo -archs "$app/Contents/MacOS/DevBar")"
[[ " $architectures " == *" arm64 "* && " $architectures " == *" x86_64 "* ]] || { echo 'Missing universal architecture.' >&2; exit 1; }
codesign --force --sign - "$app"
codesign --verify --strict "$app"
"$app/Contents/MacOS/DevBar" --version
cp "$binary_dir/DevBar" "$staging/DevBar"
cp README.md LICENSE RELEASING.md CONTRIBUTING.md CHANGELOG.md "$staging/"
ditto -c -k --sequesterRsrc --keepParent "$app" "$output/DevBar-$version-macos-universal.zip"
tar -czf "$output/DevBar-$version-cli-macos-universal.tar.gz" -C "$staging" DevBar README.md LICENSE RELEASING.md CONTRIBUTING.md CHANGELOG.md
(cd "$output" && shasum -a 256 "DevBar-$version-macos-universal.zip" "DevBar-$version-cli-macos-universal.tar.gz" > "DevBar-$version-SHA256SUMS.txt")
echo "Release packages: $output"
