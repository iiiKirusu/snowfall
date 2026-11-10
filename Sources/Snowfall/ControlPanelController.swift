import AppKit

/// Hides the panel when the user presses Escape.
private final class PanelWindow: NSWindow {
    override func cancelOperation(_ sender: Any?) {
        orderOut(nil)
    }
}

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
    private let lightsCheckbox = NSButton(checkboxWithTitle: "Christmas Lights", target: nil, action: nil)
    private let leavesCheckbox = NSButton(checkboxWithTitle: "Autumn Leaves", target: nil, action: nil)
    private let spaceCheckbox = NSButton(checkboxWithTitle: "Space Stars", target: nil, action: nil)
    private let loginCheckbox = NSButton(checkboxWithTitle: "Open at Login", target: nil, action: nil)
    private let hideButton = NSButton(title: "Hide Window", target: nil, action: nil)
    private let customizeButton = NSButton(title: "Customize…", target: nil, action: nil)
    private let creditsButton = NSButton(title: "Credits", target: nil, action: nil)
    private let quitButton = NSButton(title: "Quit Snowfall", target: nil, action: nil)

    override init() {
        window = PanelWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 600),
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

    func hide() {
        window.orderOut(nil)
    }

    func refresh() {
        let snowing = Settings.isSnowing
        let lights = Settings.lightsEnabled
        let leaves = Settings.leavesEnabled
        let space = Settings.spaceEnabled

        var active: [String] = []
        if snowing { active.append("Snow") }
        if lights { active.append("Christmas lights") }
        if leaves { active.append("Autumn leaves") }
        if space { active.append("Space stars") }

        if active.isEmpty {
            statusLabel.stringValue = "Everything is off"
        } else if active.count == 1 {
            statusLabel.stringValue = "\(active[0]) is on"
        } else {
            statusLabel.stringValue = active.joined(separator: " + ") + " are on"
        }

        toggleButton.title = snowing ? "Turn Snow Off" : "Turn Snow On"
        intensityControl.selectedSegment = Settings.intensity.rawValue

        lightsCheckbox.state = lights ? .on : .off
        leavesCheckbox.state = leaves ? .on : .off
        spaceCheckbox.state = space ? .on : .off
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

        let subtitleLabel = NSTextField(labelWithString: "A little atmosphere for your desktop.")
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

        lightsCheckbox.target = self
        lightsCheckbox.action = #selector(toggleLights)

        leavesCheckbox.target = self
        leavesCheckbox.action = #selector(toggleLeaves)

        spaceCheckbox.target = self
        spaceCheckbox.action = #selector(toggleSpace)

        loginCheckbox.target = self
        loginCheckbox.action = #selector(toggleLogin)

        customizeButton.bezelStyle = .rounded
        customizeButton.font = .systemFont(ofSize: 12, weight: .medium)
        customizeButton.controlSize = .small
        customizeButton.target = self
        customizeButton.action = #selector(openAtmosphere)

        creditsButton.bezelStyle = .rounded
        creditsButton.font = .systemFont(ofSize: 12, weight: .medium)
        creditsButton.controlSize = .small
        creditsButton.target = self
        creditsButton.action = #selector(openCredits)

        hideButton.isBordered = false
        hideButton.font = .systemFont(ofSize: 11)
        hideButton.contentTintColor = NSColor.white.withAlphaComponent(0.6)
        hideButton.target = self
        hideButton.action = #selector(hidePanel)
        hideButton.keyEquivalent = "w"
        hideButton.keyEquivalentModifierMask = [.command]

        quitButton.isBordered = false
        quitButton.font = .systemFont(ofSize: 11)
        quitButton.contentTintColor = NSColor.white.withAlphaComponent(0.6)
        quitButton.target = self
        quitButton.action = #selector(quit)

        let footer = NSStackView(views: [hideButton, quitButton])
        footer.orientation = .horizontal
        footer.spacing = 18

        let extras = NSStackView(views: [customizeButton, creditsButton])
        extras.orientation = .horizontal
        extras.spacing = 10

        let stack = NSStackView(views: [
            iconView,
            titleLabel,
            subtitleLabel,
            statusLabel,
            toggleButton,
            intensityControl,
            lightsCheckbox,
            leavesCheckbox,
            spaceCheckbox,
            extras,
            loginCheckbox,
            footer
        ])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 11
        stack.setCustomSpacing(18, after: subtitleLabel)
        stack.setCustomSpacing(24, after: statusLabel)
        stack.setCustomSpacing(16, after: intensityControl)
        stack.setCustomSpacing(6, after: lightsCheckbox)
        stack.setCustomSpacing(6, after: leavesCheckbox)
        stack.setCustomSpacing(14, after: spaceCheckbox)
        stack.setCustomSpacing(14, after: extras)
        stack.setCustomSpacing(18, after: loginCheckbox)
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
        SnowController.shared.sync()
        refresh()
        NotificationCenter.default.post(name: .snowfallStateChanged, object: nil)
    }

    @objc private func changeIntensity() {
        guard let intensity = Intensity(rawValue: intensityControl.selectedSegment) else { return }
        Settings.setIntensity(intensity)
        SnowController.shared.applyIntensity()
        NotificationCenter.default.post(name: .snowfallStateChanged, object: nil)
    }

    @objc private func toggleLights() {
        Settings.setLightsEnabled(lightsCheckbox.state == .on)
        SnowController.shared.sync()
        refresh()
        NotificationCenter.default.post(name: .snowfallStateChanged, object: nil)
    }

    @objc private func toggleLeaves() {
        Settings.setLeavesEnabled(leavesCheckbox.state == .on)
        SnowController.shared.sync()
        refresh()
        NotificationCenter.default.post(name: .snowfallStateChanged, object: nil)
    }

    @objc private func toggleSpace() {
        Settings.setSpaceEnabled(spaceCheckbox.state == .on)
        SnowController.shared.sync()
        refresh()
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

    @objc private func openAtmosphere() {
        NotificationCenter.default.post(name: .snowfallOpenAtmosphere, object: nil)
    }

    @objc private func openCredits() {
        NotificationCenter.default.post(name: .snowfallOpenCredits, object: nil)
    }

    @objc private func hidePanel() {
        hide()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
