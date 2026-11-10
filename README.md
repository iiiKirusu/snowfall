# Snowfall ❄️

A tiny native macOS menu-bar app that makes it snow on your desktop wallpaper — and lets you turn it off whenever you want.

The snow lives in a click-through window **above your wallpaper and behind your desktop icons**, so it feels like part of the wallpaper instead of an app floating on top. It works on every connected display.

## Features

- Falling snow with two depth layers: soft distant flakes and closer, detailed snowflakes
- A friendly control panel that appears whenever you open the app, with a **Hide Window** button (or press Esc)
- Menu-bar snowflake toggles the snow on and off (with a gentle fade)
- Intensity: **Light**, **Cozy**, or **Blizzard**
- Optional **Christmas Lights**: a warm, twinkling fairy-light garland around the desktop, tucked below the menu bar and above the Dock
- Optional **Autumn Leaves**: maple, oak and amber leaves drifting down over your wallpaper
- Optional **Space Stars**: a deep-space theme — a dark night sky with a starfield, twinkling stars and shooting stars
- Optional **Open at Login**
- No Dock icon, no permissions required
- Self-contained Swift app — no third-party dependencies

## Build it

Requires macOS 13 or newer and the Xcode Command Line Tools.

```bash
./Scripts/build-app.sh
open dist/Snowfall.app
```

The built app appears at `dist/Snowfall.app`.

## Make a DMG to share

```bash
./Scripts/build-app.sh
./Scripts/make-dmg.sh
```

Send `dist/Snowfall-1.1.0.dmg` to your girlfriend (AirDrop, iCloud, whatever). She opens it, drags **Snowfall** to **Applications**, and opens it.

Because the app is signed ad hoc rather than with a paid Apple Developer certificate, Gatekeeper may block the first launch. If macOS will not open it:

1. Try **right-click → Open** first (works on many macOS versions).
2. If that is not offered, open **System Settings → Privacy & Security**, scroll down, and click **Open Anyway** next to Snowfall.
3. Last resort, in Terminal: `xattr -dr com.apple.quarantine /Applications/Snowfall.app`

This is normal for apps shared outside the App Store without a developer subscription, and it only happens once.

## Use

Opening **Snowfall** shows a small control panel with a big on/off button, intensity picker, and Christmas Lights toggle. Hide it with the **Hide Window** button, the close button, or **Esc** — the app keeps running in the menu bar.

Look for the snowflake in the menu bar:

- **Snowfall Controls…** — reopen the control panel
- **Hide Controls** — tuck the panel away
- **Let It Snow** — turn the snow on or off
- **Intensity** — Light / Cozy / Blizzard
- **Christmas Lights** — turn the glowing garland on or off
- **Autumn Leaves** — turn drifting fall leaves on or off
- **Space Stars** — turn the starry space sky on or off
- **Open at Login** — start Snowfall automatically when you log in (move it to `/Applications` first)
- **Quit Snowfall** — stop the app completely

Settings are remembered between launches.

## Uninstall

Turn off **Open at Login**, choose **Quit Snowfall**, then drag the app to the Trash.

## How it works

- `Sources/Snowfall/SnowWindow.swift` — borderless, click-through window at the desktop window level (`CGWindowLevelForKey(.desktopWindow) + 1`)
- `Sources/Snowfall/SnowView.swift` — two `CAEmitterLayer`s of snow particles, scaled per display
- `Sources/Snowfall/LightsView.swift` — a sagging wire of warm, twinkling fairy lights around the desktop
- `Sources/Snowfall/LeavesView.swift` — autumn leaf sprites and the emitter that blows them across the screen
- `Sources/Snowfall/SpaceView.swift` — the space theme: nebula, starfield, twinkling stars and shooting stars
- `Sources/Snowfall/SnowTextures.swift` — snowflake and soft-dot sprites drawn at runtime with Core Graphics
- `Sources/Snowfall/AppDelegate.swift` — menu-bar item, settings, login item
- `Scripts/generate-icon.swift` — draws the app icon at every size, then `iconutil` converts it to `.icns`

## Tweaking

Some fun knobs:

- Snow density per intensity: `Intensity.targetCount` in `Sources/Snowfall/Settings.swift`
- Flake size, speed, drift, and fade: `farSpecs` / `nearSpecs` in `Sources/Snowfall/SnowView.swift`
- Icon art: `Scripts/generate-icon.swift`

Made with love. Merry Christmas! 🎄
