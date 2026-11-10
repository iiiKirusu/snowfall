import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let snow = SnowController.shared
    private let menu = NSMenu()
    private lazy var panel = ControlPanelController()
    private lazy var chat = ChatService()
    private lazy var chatWindow = ChatWindowController(chat: chat)

    private var statusItem: NSStatusItem!
    private var toggleItem: NSMenuItem!
    private var chatItem: NSMenuItem!
    private var loginItem: NSMenuItem!
    private var lightsItem: NSMenuItem!
    private var intensityItems: [NSMenuItem] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureStatusItem()
        buildMenu()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(stateChanged),
            name: .snowfallStateChanged,
            object: nil
        )
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(showControls),
            name: .snowfallShowControls,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(chatStateChanged),
            name: .snowfallChatChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openChat),
            name: .snowfallOpenChat,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        let defaults = UserDefaults.standard
        if defaults.object(forKey: Settings.snowingKey) == nil {
            defaults.set(true, forKey: Settings.snowingKey)
        }
        if defaults.object(forKey: Settings.intensityKey) == nil {
            Settings.setIntensity(.cozy)
        }
        if defaults.object(forKey: Settings.lightsKey) == nil {
            Settings.setLightsEnabled(true)
        }

        if Settings.isSnowing {
            snow.start()
        }
        chat.start()
        chatWindow.onBack = { [weak self] in
            self?.panel.show()
        }
        refreshMenuState()
        refreshChatMenu()

        // Always show the control window on launch so it is obvious the app
        // opened. Hiding it keeps everything running in the menu bar.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.panel.show()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        panel.show()
        return true
    }

    // MARK: - Menu bar

    private func configureStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            let configuration = NSImage.SymbolConfiguration(pointSize: 15, weight: .medium)
            let image = NSImage(systemSymbolName: "snowflake", accessibilityDescription: "Snowfall")?
                .withSymbolConfiguration(configuration)
            image?.isTemplate = true
            button.image = image
            button.toolTip = "Snowfall"
        }

        statusItem.menu = menu
    }

    private func buildMenu() {
        menu.autoenablesItems = false

        let controlsItem = NSMenuItem(title: "Snowfall Controls…", action: #selector(showControls), keyEquivalent: ",")
        controlsItem.target = self
        menu.addItem(controlsItem)

        let hideItem = NSMenuItem(title: "Hide Controls", action: #selector(hideControls), keyEquivalent: "")
        hideItem.target = self
        menu.addItem(hideItem)

        chatItem = NSMenuItem(title: "Snowfall Chat…", action: #selector(openChat), keyEquivalent: "")
        chatItem.target = self
        menu.addItem(chatItem)

        menu.addItem(.separator())

        toggleItem = NSMenuItem(title: "Let It Snow", action: #selector(toggleSnow), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)

        let intensityRoot = NSMenuItem(title: "Intensity", action: nil, keyEquivalent: "")
        let intensityMenu = NSMenu()
        for intensity in Intensity.allCases {
            let item = NSMenuItem(title: intensity.title, action: #selector(selectIntensity(_:)), keyEquivalent: "")
            item.tag = intensity.rawValue
            item.target = self
            intensityMenu.addItem(item)
            intensityItems.append(item)
        }
        intensityRoot.submenu = intensityMenu
        menu.addItem(intensityRoot)

        lightsItem = NSMenuItem(title: "Christmas Lights", action: #selector(toggleLights), keyEquivalent: "")
        lightsItem.target = self
        menu.addItem(lightsItem)

        menu.addItem(.separator())

        loginItem = NSMenuItem(title: "Open at Login", action: #selector(toggleLoginItem), keyEquivalent: "")
        loginItem.target = self
        menu.addItem(loginItem)

        let aboutItem = NSMenuItem(title: "About Snowfall", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit Snowfall", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    private func refreshMenuState() {
        let snowing = Settings.isSnowing
        let lights = Settings.lightsEnabled

        toggleItem.state = snowing ? .on : .off
        lightsItem.state = lights ? .on : .off
        statusItem.button?.alphaValue = (snowing || lights) ? 1.0 : 0.4

        for item in intensityItems {
            item.state = item.tag == Settings.intensity.rawValue ? .on : .off
        }

        loginItem.isEnabled = LoginItem.isAvailable
        loginItem.state = LoginItem.isEnabled ? .on : .off
    }

    // MARK: - Actions

    @objc private func showControls() {
        panel.show()
    }

    @objc private func hideControls() {
        panel.hide()
    }

    @objc private func openChat() {
        chatWindow.show()
    }

    @objc private func chatStateChanged() {
        refreshChatMenu()
    }

    private func refreshChatMenu() {
        let unread = chat.unreadCount
        chatItem.title = unread > 0 ? "Snowfall Chat (\(unread) new)" : "Snowfall Chat…"
    }

    @objc private func systemDidWake() {
        chat.reconnectNow()
    }

    @objc private func stateChanged() {
        refreshMenuState()
    }

    @objc private func toggleSnow() {
        Settings.setSnowing(!Settings.isSnowing)
        snow.sync()
        refreshMenuState()
        NotificationCenter.default.post(name: .snowfallStateChanged, object: nil)
    }

    @objc private func toggleLights() {
        Settings.setLightsEnabled(!Settings.lightsEnabled)
        snow.sync()
        refreshMenuState()
        NotificationCenter.default.post(name: .snowfallStateChanged, object: nil)
    }

    @objc private func selectIntensity(_ sender: NSMenuItem) {
        guard let intensity = Intensity(rawValue: sender.tag) else { return }
        Settings.setIntensity(intensity)
        snow.applyIntensity()
        refreshMenuState()
        NotificationCenter.default.post(name: .snowfallStateChanged, object: nil)
    }

    @objc private func toggleLoginItem() {
        do {
            try LoginItem.setEnabled(!LoginItem.isEnabled)
        } catch {
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

        refreshMenuState()
        NotificationCenter.default.post(name: .snowfallStateChanged, object: nil)
    }

    @objc private func screenParametersChanged() {
        if Settings.isSnowing || Settings.lightsEnabled {
            snow.rebuild()
        }
    }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "Snowfall ❄️"
        alert.informativeText = """
        A little Christmas snow for your desktop.

        Click the snowflake in the menu bar, or open Snowfall again, to show the controls.

        Made with love. Merry Christmas!
        """
        alert.addButton(withTitle: "Close")
        alert.icon = NSApp.applicationIconImage
        alert.runModal()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
