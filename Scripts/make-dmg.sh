#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"

VERSION="1.4.0"
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
3. If macOS says it can't verify the app, do one of these (only needed once):
   • Right-click Snowfall and choose Open, then click "Open" again.
   • Or open System Settings → Privacy & Security, scroll down, and click
     "Open Anyway" next to Snowfall.

USE
• A Snowfall control panel opens when you launch the app.
• Use the big button to turn the snow on and off.
• Tick "Christmas Lights" for a warm, twinkling garland around the screen.
• Tick "Autumn Leaves" for drifting fall leaves.
• Tick "Space Stars" for a starry night sky with shooting stars.
• Click "Customize…" to change the light colour, light brightness, and how
  many leaves fall and how fast.
• Click "Hide Window" (or press Esc) to tuck the panel away.
• You can also use the snowflake in your menu bar at any time.
• "Intensity" picks Light, Cozy, or Blizzard.
• "Open at Login" starts the snow automatically when you log in.

UNINSTALL
Turn off "Open at Login", quit Snowfall from the menu, then move it to the Trash.

Made with love. Merry Christmas!
TXT

rm -f "$DMG"
hdiutil create -volname "Snowfall" -srcfolder "$STAGE" -ov -format UDZO -quiet "$DMG"

echo "Done: $DMG"
