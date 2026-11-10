import AppKit

/// Owns one snow window per display.
final class SnowController {
    static let shared = SnowController()

    private var windows: [SnowWindow] = []

    var isSnowing: Bool {
        !windows.isEmpty
    }

    func start() {
        guard windows.isEmpty else { return }

        for screen in NSScreen.screens {
            let window = SnowWindow(screen: screen, intensity: Settings.intensity)
            windows.append(window)
            window.orderFrontRegardless()
            window.snowView.fadeIn()
        }
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
        guard isSnowing else { return }
        stop(animated: false)
        start()
    }

    func applyIntensity() {
        for window in windows {
            window.applyIntensity(Settings.intensity)
        }
    }
}
