import AppKit

/// A click-through window that sits just above the wallpaper and behind desktop icons.
final class SnowWindow: NSWindow {
    let snowView: SnowView

    init(screen: NSScreen, intensity: Intensity) {
        let screenFrame = screen.frame
        snowView = SnowView(
            frame: NSRect(origin: .zero, size: screenFrame.size),
            intensity: intensity,
            backingScale: screen.backingScaleFactor
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
        contentView = snowView
        setFrame(screenFrame, display: false)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func applyIntensity(_ intensity: Intensity) {
        snowView.applyIntensity(intensity)
    }

    func fadeOutAndClose() {
        snowView.fadeOut { [self] in
            orderOut(nil)
            close()
        }
    }
}
