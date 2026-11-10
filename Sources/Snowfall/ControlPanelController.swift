import AppKit

/// A small, friendly control window. This is the visible "face" of the app,
/// so opening Snowfall always does something obvious — even when it is already running.
final class ControlPanelController: NSObject, NSWindowDelegate {
    private let window: NSWindow
    private let statusLabel = NSTextField(labelWithString: "")
    private let toggleButton = NSButton(title: "Turn Snow Off", target: nil, action: nil)
    private let intensityControl = NSSegmentedControl(
        labels: ["Light", "Cozy", "Blizzard"],
        trackingMode: .selectOne,
        target: nil,
        action: nil
    )
    private let loginCheckbox = NSButton(checkboxWithTitle: "Open at Login", target: nil, action: nil)
    private let quitButton = NSButton(title: "Quit Snowfall", target: nil, action: nil)

    override init() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 440),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        super.init()

        configureWindow()
        buildContent()
        refresh()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(stateChanged),
            name: .snowfallStateChanged,
            object: nil
        )
    }

    func show() {
        refresh()
        NSApp.activate(ignoringOtherApps: true)
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    func refresh() {
        let snowing = Settings.isSnowing

        statusLabel.stringValue = snowing ? "Snow is falling on your desktop ❄️" : "Snow is paused"
        toggleButton.title = snowing ? "Turn Snow Off" : "Turn Snow On"

        intensityControl.selectedSegment = Settings.intensity.rawValue

        loginCheckbox.isEnabled = LoginItem.isAvailable
        loginCheckbox.state = LoginItem.isEnabled ? .on : .off
    }

    // MARK: - Window

    private func configureWindow() {
        window.title = "Snowfall"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.moveToActiveSpace]
        window.tabbingMode = .disallowed
        window.appearance = NSAppearance(named: .darkAqua)
        window.delegate = self
    }

    private func buildContent() {
        let background = NSVisualEffectView()
        background.material = .hudWindow
        background.blendingMode = .behindWindow
        background.state = .active
        window.contentView = background

        let iconView = NSImageView()
        iconView.image = NSApp.applicationIconImage
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = NSTextField(labelWithString: "Snowfall")
        titleLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        titleLabel.textColor = .white

        let subtitleLabel = NSTextField(labelWithString: "Snow on your desktop, all winter long.")
        subtitleLabel.font = .systemFont(ofSize: 12)
        subtitleLabel.textColor = NSColor.white.withAlphaComponent(0.55)

        statusLabel.font = .systemFont(ofSize: 13, weight: .medium)
        statusLabel.textColor = NSColor(calibratedRed: 0.70, green: 0.86, blue: 1.0, alpha: 1.0)

        toggleButton.bezelStyle = .rounded
        toggleButton.controlSize = .large
        toggleButton.font = .systemFont(ofSize: 13, weight: .semibold)
        toggleButton.keyEquivalent = "\r"
        toggleButton.target = self
        toggleButton.action = #selector(toggleSnow)

        intensityControl.target = self
        intensityControl.action = #selector(changeIntensity)

        loginCheckbox.target = self
        loginCheckbox.action = #selector(toggleLogin)

        quitButton.isBordered = false
        quitButton.font = .systemFont(ofSize: 11)
        quitButton.contentTintColor = NSColor.white.withAlphaComponent(0.55)
        quitButton.target = self
        quitButton.action = #selector(quit)

        let stack = NSStackView(views: [
            iconView,
            titleLabel,
            subtitleLabel,
            statusLabel,
            toggleButton,
            intensityControl,
            loginCheckbox,
            quitButton
        ])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 12
        stack.setCustomSpacing(18, after: subtitleLabel)
        stack.setCustomSpacing(24, after: statusLabel)
        stack.setCustomSpacing(20, after: intensityControl)
        stack.translatesAutoresizingMaskIntoConstraints = false

        background.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: background.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: background.centerYAnchor, constant: 2),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: background.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: background.trailingAnchor, constant: -28),

            iconView.widthAnchor.constraint(equalToConstant: 84),
            iconView.heightAnchor.constraint(equalToConstant: 84),
            toggleButton.widthAnchor.constraint(equalToConstant: 230),
            intensityControl.widthAnchor.constraint(equalToConstant: 250)
        ])
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        true
    }

    // MARK: - Actions

    @objc private func stateChanged() {
        refresh()
    }

    @objc private func toggleSnow() {
        Settings.setSnowing(!Settings.isSnowing)

        if Settings.isSnowing {
            SnowController.shared.start()
        } else {
            SnowController.shared.stop()
        }

        refresh()
        NotificationCenter.default.post(name: .snowfallStateChanged, object: nil)
    }

    @objc private func changeIntensity() {
        guard let intensity = Intensity(rawValue: intensityControl.selectedSegment) else { return }
        Settings.setIntensity(intensity)
        SnowController.shared.applyIntensity()
        NotificationCenter.default.post(name: .snowfallStateChanged, object: nil)
    }

    @objc private func toggleLogin() {
        let shouldEnable = loginCheckbox.state == .on

        do {
            try LoginItem.setEnabled(shouldEnable)
        } catch {
            presentLoginItemError(error)
        }

        refresh()
        NotificationCenter.default.post(name: .snowfallStateChanged, object: nil)
    }

    private func presentLoginItemError(_ error: Error) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Couldn’t update the login item"
        alert.informativeText = """
        \(error.localizedDescription)

        Tip: move Snowfall to your Applications folder first, then try again.
        """
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
