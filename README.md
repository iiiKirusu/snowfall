# Snowfall ❄️

A tiny native macOS menu-bar app that makes it snow on your desktop wallpaper — and lets you turn it off whenever you want.

The snow lives in a click-through window **above your wallpaper and behind your desktop icons**, so it feels like part of the wallpaper instead of an app floating on top. It works on every connected display.

## Features

- Falling snow with two depth layers: soft distant flakes and closer, detailed snowflakes
- Menu-bar snowflake toggles the snow on and off (with a gentle fade)
- Intensity: **Light**, **Cozy**, or **Blizzard**
- Optional **Open at Login**
- No Dock icon, no window, no permissions, no network access
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

Send `dist/Snowfall-1.0.0.dmg` to your girlfriend (AirDrop, iCloud, whatever). She opens it, drags **Snowfall** to **Applications**, and opens it. Because the app is signed ad hoc rather than with a paid Apple Developer certificate, macOS may ask her to **right-click → Open** the first time. That is normal and only happens once.

## Use

Look for the snowflake in the menu bar:

- **Let It Snow** — turn the snow on or off
- **Intensity** — Light / Cozy / Blizzard
- **Open at Login** — start Snowfall automatically when you log in (move it to `/Applications` first)
- **Quit Snowfall** — stop the app completely

Settings are remembered between launches.

## Uninstall

Turn off **Open at Login**, choose **Quit Snowfall**, then drag the app to the Trash.

## How it works

- `Sources/Snowfall/SnowWindow.swift` — borderless, click-through window at the desktop window level (`CGWindowLevelForKey(.desktopWindow) + 1`)
- `Sources/Snowfall/SnowView.swift` — two `CAEmitterLayer`s of snow particles, scaled per display
- `Sources/Snowfall/SnowTextures.swift` — snowflake and soft-dot sprites drawn at runtime with Core Graphics
- `Sources/Snowfall/AppDelegate.swift` — menu-bar item, settings, login item
- `Scripts/generate-icon.swift` — draws the app icon at every size, then `iconutil` converts it to `.icns`

## Tweaking

Some fun knobs:

- Snow density per intensity: `Intensity.targetCount` in `Sources/Snowfall/Settings.swift`
- Flake size, speed, drift, and fade: `farSpecs` / `nearSpecs` in `Sources/Snowfall/SnowView.swift`
- Icon art: `Scripts/generate-icon.swift`

Made with love. Merry Christmas! 🎄
