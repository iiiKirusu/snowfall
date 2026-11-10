import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let snow = SnowController.shared
    private let menu = NSMenu()

    private var statusItem: NSStatusItem!
    private var toggleItem: NSMenuItem!
    private var loginItem: NSMenuItem!
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

        let defaults = UserDefaults.standard
        if defaults.object(forKey: Settings.snowingKey) == nil {
            defaults.set(true, forKey: Settings.snowingKey)
        }
        if defaults.object(forKey: Settings.intensityKey) == nil {
            Settings.setIntensity(.cozy)
        }

        if Settings.isSnowing {
            snow.start()
        }
        refreshMenuState()

        if !defaults.bool(forKey: "didWelcome") {
            defaults.set(true, forKey: "didWelcome")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.showWelcome()
            }
        }
    }

    // MARK: - Menu bar

    private func configureStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "snowflake", accessibilityDescription: "Snowfall")
            image?.isTemplate = true
            button.image = image
            button.toolTip = "Snowfall"
        }

        statusItem.menu = menu
    }

    private func buildMenu() {
        menu.autoenablesItems = false

        let titleItem = NSMenuItem(title: "Snowfall", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
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
        toggleItem.state = snowing ? .on : .off
        statusItem.button?.alphaValue = snowing ? 1.0 : 0.4

        for item in intensityItems {
            item.state = item.tag == Settings.intensity.rawValue ? .on : .off
        }

        loginItem.isEnabled = Bundle.main.bundleURL.pathExtension == "app"
        loginItem.state = loginItemEnabled ? .on : .off
    }

    private var loginItemEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    // MARK: - Actions

    @objc private func toggleSnow() {
        Settings.setSnowing(!Settings.isSnowing)

        if Settings.isSnowing {
            snow.start()
        } else {
            snow.stop()
        }
        refreshMenuState()
    }

    @objc private func selectIntensity(_ sender: NSMenuItem) {
        guard let intensity = Intensity(rawValue: sender.tag) else { return }
        Settings.setIntensity(intensity)
        snow.applyIntensity()
        refreshMenuState()
    }

    @objc private func toggleLoginItem() {
        do {
            if loginItemEnabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
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
    }

    @objc private func screenParametersChanged() {
        if Settings.isSnowing {
            snow.rebuild()
        }
    }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "Snowfall ❄️"
        alert.informativeText = """
        A little Christmas snow for your desktop.

        Click the snowflake in the menu bar to turn the snow on or off, choose an intensity, or have Snowfall open at login.

        Made with love. Merry Christmas!
        """
        alert.addButton(withTitle: "Close")
        alert.icon = NSApp.applicationIconImage
        alert.runModal()
    }

    private func showWelcome() {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "Merry Christmas ❄️"
        alert.informativeText = """
        Snowfall is now making it snow on your desktop.

        Look for the snowflake in your menu bar to turn the snow on or off, pick an intensity, or have Snowfall open at login.
        """
        alert.addButton(withTitle: "Let it snow")
        alert.icon = NSApp.applicationIconImage
        alert.runModal()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
