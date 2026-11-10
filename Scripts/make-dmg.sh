#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"

VERSION="1.0.0"
APP="$ROOT/dist/Snowfall.app"
DMG="$ROOT/dist/Snowfall-$VERSION.dmg"

if [ ! -d "$APP" ]; then
    echo "Snowfall.app not found. Run Scripts/build-app.sh first." >&2
    exit 1
fi

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

cp -R "$APP" "$STAGE/Snowfall.app"
ln -s /Applications "$STAGE/Applications"

cat > "$STAGE/Read Me.txt" <<'TXT'
Snowfall ❄️ — a little Christmas snow for your Mac desktop.

INSTALL
1. Drag Snowfall to the Applications folder.
2. Open Snowfall from Applications.
3. If macOS says it can't verify the app, right-click Snowfall and choose Open,
   then click "Open" again. You only have to do this once.

USE
• Look for the snowflake in your menu bar.
• "Let It Snow" turns the snow on and off.
• "Intensity" picks Light, Cozy, or Blizzard.
• "Open at Login" starts the snow automatically when you log in.

UNINSTALL
Turn off "Open at Login", quit Snowfall from the menu, then move it to the Trash.

Made with love. Merry Christmas!
TXT

rm -f "$DMG"
hdiutil create -volname "Snowfall" -srcfolder "$STAGE" -ov -format UDZO -quiet "$DMG"

echo "Done: $DMG"
