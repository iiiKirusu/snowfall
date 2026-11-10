import Foundation

enum Intensity: Int, CaseIterable {
    case light = 0
    case cozy = 1
    case blizzard = 2

    var title: String {
        switch self {
        case .light: return "Light"
        case .cozy: return "Cozy"
        case .blizzard: return "Blizzard"
        }
    }

    /// Approximate number of snowflakes on a 1920 x 1080 display.
    var targetCount: Double {
        switch self {
        case .light: return 70
        case .cozy: return 240
        case .blizzard: return 760
        }
    }

    /// How fast the flakes fall.
    var speedMultiplier: Double {
        switch self {
        case .light: return 0.5
        case .cozy: return 1.0
        case .blizzard: return 2.1
        }
    }

    /// How big the flakes look.
    var sizeMultiplier: Double {
        switch self {
        case .light: return 0.72
        case .cozy: return 1.0
        case .blizzard: return 1.3
        }
    }

    /// How much the flakes sway sideways.
    var driftMultiplier: Double {
        switch self {
        case .light: return 0.6
        case .cozy: return 1.0
        case .blizzard: return 1.8
        }
    }
}

enum Settings {
    static let snowingKey = "snowing"
    static let intensityKey = "intensity"
    static let lightsKey = "lights"
    static let leavesKey = "leaves"
    static let spaceKey = "space"

    static var isSnowing: Bool {
        UserDefaults.standard.bool(forKey: snowingKey)
    }

    static func setSnowing(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: snowingKey)
    }

    static var intensity: Intensity {
        guard UserDefaults.standard.object(forKey: intensityKey) != nil else {
            return .cozy
        }
        return Intensity(rawValue: UserDefaults.standard.integer(forKey: intensityKey)) ?? .cozy
    }

    static func setIntensity(_ intensity: Intensity) {
        UserDefaults.standard.set(intensity.rawValue, forKey: intensityKey)
    }

    static var lightsEnabled: Bool {
        guard UserDefaults.standard.object(forKey: lightsKey) != nil else {
            return true
        }
        return UserDefaults.standard.bool(forKey: lightsKey)
    }

    static func setLightsEnabled(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: lightsKey)
    }

    static var leavesEnabled: Bool {
        guard UserDefaults.standard.object(forKey: leavesKey) != nil else {
            return false
        }
        return UserDefaults.standard.bool(forKey: leavesKey)
    }

    static func setLeavesEnabled(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: leavesKey)
    }

    static var spaceEnabled: Bool {
        guard UserDefaults.standard.object(forKey: spaceKey) != nil else {
            return false
        }
        return UserDefaults.standard.bool(forKey: spaceKey)
    }

    static func setSpaceEnabled(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: spaceKey)
    }
}
