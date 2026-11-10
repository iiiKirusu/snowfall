# Snowfall ❄️

A tiny native macOS menu-bar app that makes it snow on your desktop wallpaper — and lets you turn it off whenever you want.

The snow lives in a click-through window **above your wallpaper and behind your desktop icons**, so it feels like part of the wallpaper instead of an app floating on top. It works on every connected display.

## Features

- Falling snow with two depth layers: soft distant flakes and closer, detailed snowflakes
- A friendly control panel that appears whenever you open the app, with a **Hide Window** button (or press Esc)
- Menu-bar snowflake toggles the snow on and off (with a gentle fade)
- Intensity: **Light**, **Cozy**, or **Blizzard**
- Optional **Christmas Lights**: a warm, twinkling fairy-light garland around the desktop, tucked below the menu bar and above the Dock
- A private **two-person chat** with end-to-end encryption — pair two Macs with an invite code
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

Send `dist/Snowfall-1.0.0.dmg` to your girlfriend (AirDrop, iCloud, whatever). She opens it, drags **Snowfall** to **Applications**, and opens it.

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
- **Snowfall Chat…** — open the chat window (shows “new” when there are unread messages)
- **Let It Snow** — turn the snow on or off
- **Intensity** — Light / Cozy / Blizzard
- **Christmas Lights** — turn the glowing garland on or off
- **Open at Login** — start Snowfall automatically when you log in (move it to `/Applications` first)
- **Quit Snowfall** — stop the app completely

Settings are remembered between launches.

## Chat with your person

Snowfall has a little chat just for the two of you. It works between two Macs anywhere in the world — no accounts, no server to run, and no messages stored in the cloud.

### Pair your Macs

1. On your Mac, open **Snowfall Chat** and click **Create Our Invite Code**.
2. A code like `SNOW-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX` appears. Click **Copy Code** and send it to her (iMessage, AirDrop, whatever).
3. On her Mac, open **Snowfall Chat**, paste the code into **Have a code from her?**, and click **Join**.
4. You’re connected. Say hi ❄️

The code is effectively your shared password. Anyone who has it can join the conversation, so keep it between the two of you. You can copy it again from the **⋯** menu → **Copy Invite Code**, or **Unpair** if you ever need to start over.

### Privacy

Messages are encrypted on your Mac with an AES-GCM key derived from the invite code, then relayed through the public [ntfy.sh](https://ntfy.sh) service. The relay only ever sees scrambled data — it cannot read your messages. Snowfall keeps a local copy of the last 300 messages on each Mac, and nothing else.

The chat reconnects automatically after sleep or a network drop, and the menu shows an unread count when new messages arrive.

## Uninstall

Turn off **Open at Login**, choose **Quit Snowfall**, then drag the app to the Trash.

## How it works

- `Sources/Snowfall/SnowWindow.swift` — borderless, click-through window at the desktop window level (`CGWindowLevelForKey(.desktopWindow) + 1`)
- `Sources/Snowfall/SnowView.swift` — two `CAEmitterLayer`s of snow particles, scaled per display
- `Sources/Snowfall/LightsView.swift` — a sagging wire of warm, twinkling fairy lights around the desktop
- `Sources/Snowfall/SnowTextures.swift` — snowflake and soft-dot sprites drawn at runtime with Core Graphics
- `Sources/Snowfall/ChatService.swift` — encrypted chat transport and invite-code pairing over ntfy.sh
- `Sources/Snowfall/ChatView.swift` — the AppKit chat interface (onboarding, invite card, message bubbles)
- `Sources/Snowfall/AppDelegate.swift` — menu-bar item, settings, login item
- `Scripts/generate-icon.swift` — draws the app icon at every size, then `iconutil` converts it to `.icns`

## Tweaking

Some fun knobs:

- Snow density per intensity: `Intensity.targetCount` in `Sources/Snowfall/Settings.swift`
- Flake size, speed, drift, and fade: `farSpecs` / `nearSpecs` in `Sources/Snowfall/SnowView.swift`
- Icon art: `Scripts/generate-icon.swift`

Made with love. Merry Christmas! 🎄
