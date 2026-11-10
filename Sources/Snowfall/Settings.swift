import AppKit

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
    static let leavesDensityKey = "leaves.density"
    static let leavesSpeedKey = "leaves.speed"
    static let lightsColorKey = "lights.color"
    static let lightsBrightnessKey = "lights.brightness"
    static let authorKey = "credits.author"
    static let instagramKey = "credits.instagram"
    static let githubKey = "credits.github"

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

    /// How many leaves fall, from 0 (a few) to 1 (a blizzard of leaves).
    static var leavesDensity: Double {
        let value = UserDefaults.standard.double(forKey: leavesDensityKey)
        guard UserDefaults.standard.object(forKey: leavesDensityKey) != nil else { return 0.5 }
        return min(max(value, 0), 1)
    }

    static func setLeavesDensity(_ value: Double) {
        UserDefaults.standard.set(min(max(value, 0), 1), forKey: leavesDensityKey)
    }

    /// How fast the leaves fall, from 0 (drifting) to 1 (blown by wind).
    static var leavesSpeed: Double {
        let value = UserDefaults.standard.double(forKey: leavesSpeedKey)
        guard UserDefaults.standard.object(forKey: leavesSpeedKey) != nil else { return 0.5 }
        return min(max(value, 0), 1)
    }

    static func setLeavesSpeed(_ value: Double) {
        UserDefaults.standard.set(min(max(value, 0), 1), forKey: leavesSpeedKey)
    }

    /// The main colour of the fairy lights.
    static var lightsColor: NSColor {
        if let hex = UserDefaults.standard.string(forKey: lightsColorKey),
           let color = NSColor(hexString: hex) {
            return color
        }
        return NSColor(calibratedRed: 1.0, green: 0.86, blue: 0.62, alpha: 1)
    }

    static func setLightsColor(_ color: NSColor) {
        UserDefaults.standard.set(color.hexString ?? "", forKey: lightsColorKey)
    }

    /// How bright the fairy lights glow, from 0.15 to 1.
    static var lightsBrightness: Double {
        let value = UserDefaults.standard.double(forKey: lightsBrightnessKey)
        guard UserDefaults.standard.object(forKey: lightsBrightnessKey) != nil else { return 0.9 }
        return min(max(value, 0.15), 1)
    }

    static func setLightsBrightness(_ value: Double) {
        UserDefaults.standard.set(min(max(value, 0.15), 1), forKey: lightsBrightnessKey)
    }

    static var authorName: String {
        let value = UserDefaults.standard.string(forKey: authorKey) ?? ""
        return value.isEmpty ? "kous" : value
    }

    static func setAuthorName(_ value: String) {
        UserDefaults.standard.set(value, forKey: authorKey)
    }

    static var instagramHandle: String {
        let value = UserDefaults.standard.string(forKey: instagramKey) ?? ""
        return value.isEmpty ? "kirusuz" : value
    }

    static func setInstagramHandle(_ value: String) {
        UserDefaults.standard.set(value, forKey: instagramKey)
    }

    static var githubHandle: String {
        let value = UserDefaults.standard.string(forKey: githubKey) ?? ""
        return value.isEmpty ? "iiiKirusu" : value
    }

    static func setGithubHandle(_ value: String) {
        UserDefaults.standard.set(value, forKey: githubKey)
    }
}

extension NSColor {
    var hexString: String? {
        guard let rgb = usingColorSpace(.sRGB) else { return nil }
        let red = Int(round(rgb.redComponent * 255))
        let green = Int(round(rgb.greenComponent * 255))
        let blue = Int(round(rgb.blueComponent * 255))
        return String(format: "%02X%02X%02X", red, green, blue)
    }

    convenience init?(hexString: String) {
        var value = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("#") {
            value.removeFirst()
        }
        guard value.count == 6, let number = UInt32(value, radix: 16) else { return nil }
        self.init(
            srgbRed: CGFloat((number >> 16) & 0xFF) / 255,
            green: CGFloat((number >> 8) & 0xFF) / 255,
            blue: CGFloat(number & 0xFF) / 255,
            alpha: 1
        )
    }
}
