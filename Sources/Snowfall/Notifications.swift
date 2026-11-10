import Foundation

extension Notification.Name {
    /// Posted inside the app whenever snow on/off or intensity changes.
    static let snowfallStateChanged = Notification.Name("com.kous.snowfall.stateChanged")

    /// Posted between app copies so a second launch can ask the first one to show its controls.
    static let snowfallShowControls = Notification.Name("com.kous.snowfall.showControls")

    /// Posted by the control panel to open the atmosphere customization window.
    static let snowfallOpenAtmosphere = Notification.Name("com.kous.snowfall.openAtmosphere")

    /// Posted by the control panel to open the credits window.
    static let snowfallOpenCredits = Notification.Name("com.kous.snowfall.openCredits")
}
