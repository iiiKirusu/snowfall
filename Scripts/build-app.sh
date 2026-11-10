#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"

APP_NAME="Snowfall"
VERSION="1.3.0"
BUILD_NUMBER="$(date +%Y%m%d%H%M)"
DIST="$ROOT/dist"
BUNDLE="$DIST/$APP_NAME.app"

echo "==> Building Snowfall"
if swift build -c release --arch arm64 --arch x86_64; then
    BIN_DIR="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)"
else
    echo "    Universal build unavailable, building for this Mac only."
    swift build -c release
    BIN_DIR="$(swift build -c release --show-bin-path)"
fi

echo "==> Assembling $APP_NAME.app"
rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"
cp "$BIN_DIR/$APP_NAME" "$BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$BUNDLE/Contents/MacOS/$APP_NAME"

echo "==> Drawing app icon"
ICONSET="$ROOT/.build/$APP_NAME.iconset"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"
swift "$ROOT/Scripts/generate-icon.swift" "$ICONSET"
iconutil -c icns "$ICONSET" -o "$BUNDLE/Contents/Resources/AppIcon.icns"

echo "==> Writing Info.plist"
cat > "$BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.kous.snowfall</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${BUILD_NUMBER}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Made with love. Merry Christmas.</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.entertainment</string>
</dict>
</plist>
PLIST

echo "==> Signing (ad hoc)"
xattr -cr "$BUNDLE" || true
codesign --force --deep --sign - "$BUNDLE" >/dev/null

echo ""
echo "Done: $BUNDLE"
echo "Open it with: open \"$BUNDLE\""
