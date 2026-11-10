import AppKit

/// Owns one overlay window per display and keeps snow / lights in sync with settings.
final class SnowController {
    static let shared = SnowController()

    private var windows: [SnowWindow] = []

    var hasWindows: Bool {
        !windows.isEmpty
    }

    /// Applies the current settings: creates windows when needed,
    /// fades things in and out, and tears everything down when both effects are off.
    func sync(animated: Bool = true) {
        let wantsSnow = Settings.isSnowing
        let wantsLights = Settings.lightsEnabled

        guard wantsSnow || wantsLights else {
            stop(animated: animated)
            return
        }

        if windows.isEmpty {
            createWindows()
        }

        for window in windows {
            window.setSnowVisible(wantsSnow, animated: animated)
            window.setLightsVisible(wantsLights, animated: animated)
        }
    }

    func start() {
        sync()
    }

    func stop(animated: Bool = true) {
        let currentWindows = windows
        windows.removeAll()

        if animated {
            for window in currentWindows {
                window.fadeOutAndClose()
            }
        } else {
            for window in currentWindows {
                window.orderOut(nil)
                window.close()
            }
        }
    }

    func rebuild() {
        guard !windows.isEmpty else { return }
        stop(animated: false)
        sync(animated: false)
    }

    func applyIntensity() {
        for window in windows {
            window.applyIntensity(Settings.intensity)
        }
    }

    private func createWindows() {
        for screen in NSScreen.screens {
            let window = SnowWindow(screen: screen, intensity: Settings.intensity)
            windows.append(window)
            window.orderFrontRegardless()
        }
    }
}
