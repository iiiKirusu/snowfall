import AppKit

/// A click-through window that sits just above the wallpaper and behind desktop icons.
/// It hosts both the snow and the Christmas lights.
final class SnowWindow: NSWindow {
    let snowView: SnowView
    let lightsView: LightsView

    init(screen: NSScreen, intensity: Intensity) {
        let screenFrame = screen.frame

        snowView = SnowView(
            frame: NSRect(origin: .zero, size: screenFrame.size),
            intensity: intensity,
            backingScale: screen.backingScaleFactor
        )
        // Keep the lights inside the part of the desktop that is not covered
        // by the menu bar or the Dock.
        let topInset = max(screenFrame.maxY - screen.visibleFrame.maxY, 0)
        let bottomInset = max(screen.visibleFrame.minY - screenFrame.minY, 0)

        lightsView = LightsView(
            frame: NSRect(origin: .zero, size: screenFrame.size),
            backingScale: screen.backingScaleFactor,
            insets: NSEdgeInsets(top: topInset, left: 0, bottom: bottomInset, right: 0)
        )

        super.init(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        isMovable = false
        isMovableByWindowBackground = false
        isReleasedWhenClosed = false
        animationBehavior = .none

        let container = NSView(frame: NSRect(origin: .zero, size: screenFrame.size))
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.clear.cgColor
        container.layer?.masksToBounds = false

        // Lights sit behind the falling snow.
        lightsView.frame = container.bounds
        snowView.frame = container.bounds
        lightsView.autoresizingMask = [.width, .height]
        snowView.autoresizingMask = [.width, .height]
        container.addSubview(lightsView)
        container.addSubview(snowView)

        contentView = container
        setFrame(screenFrame, display: false)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func applyIntensity(_ intensity: Intensity) {
        snowView.applyIntensity(intensity)
    }

    func setSnowVisible(_ visible: Bool, animated: Bool) {
        snowView.setSnowVisible(visible, animated: animated)
    }

    func setLightsVisible(_ visible: Bool, animated: Bool) {
        lightsView.setLightsVisible(visible, animated: animated)
    }

    func fadeOutAndClose() {
        snowView.setSnowVisible(false, animated: true)
        lightsView.setLightsVisible(false, animated: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { [self] in
            orderOut(nil)
            close()
        }
    }
}
