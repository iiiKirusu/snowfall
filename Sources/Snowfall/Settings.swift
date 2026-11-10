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
        case .light: return 120
        case .cozy: return 240
        case .blizzard: return 420
        }
    }
}

enum Settings {
    static let snowingKey = "snowing"
    static let intensityKey = "intensity"

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
}
