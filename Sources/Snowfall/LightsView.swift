import AppKit
import QuartzCore

/// A warm string of Christmas fairy lights draped around the screen edges.
/// Lights are laid out along a sagging wire and each bulb twinkles on its own rhythm.
final class LightsView: NSView {
    private static let palette: [NSColor] = [
        NSColor(calibratedRed: 1.00, green: 0.88, blue: 0.66, alpha: 1), // warm white
        NSColor(calibratedRed: 1.00, green: 0.94, blue: 0.82, alpha: 1), // soft white
        NSColor(calibratedRed: 1.00, green: 0.74, blue: 0.36, alpha: 1), // gold
        NSColor(calibratedRed: 1.00, green: 0.46, blue: 0.42, alpha: 1), // red
        NSColor(calibratedRed: 0.52, green: 0.88, blue: 0.62, alpha: 1), // green
        NSColor(calibratedRed: 0.56, green: 0.80, blue: 1.00, alpha: 1)  // ice blue
    ]

    private let wireLayer = CAShapeLayer()
    private var bulbLayers: [CALayer] = []
    private let backingScale: CGFloat
    private let insets: NSEdgeInsets
    private var lastBuiltSize: NSSize = .zero
    private var isOn: Bool?

    private var baseColor: NSColor
    private var brightness: CGFloat
    private var bulbImages: [CGImage] = []
    private var bulbColorIndices: [Int] = []

    init(
        frame frameRect: NSRect,
        backingScale: CGFloat,
        insets: NSEdgeInsets = NSEdgeInsets(),
        color: NSColor = NSColor(calibratedRed: 1.0, green: 0.86, blue: 0.62, alpha: 1),
        brightness: CGFloat = 0.9
    ) {
        self.backingScale = max(backingScale, 1)
        self.insets = insets
        self.baseColor = color
        self.brightness = min(max(brightness, 0.15), 1)
        super.init(frame: frameRect)

        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.masksToBounds = false

        wireLayer.fillColor = nil
        wireLayer.lineWidth = 1.3
        wireLayer.strokeColor = NSColor(calibratedRed: 0.44, green: 0.33, blue: 0.22, alpha: 0.65).cgColor
        wireLayer.shadowRadius = 3.5
        wireLayer.shadowOpacity = 1
        wireLayer.shadowOffset = .zero
        layer?.addSublayer(wireLayer)

        refreshBulbImages()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var isOpaque: Bool { false }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        if newSize != lastBuiltSize && isOn == true {
            rebuild()
        }
    }

    func setLightsVisible(_ visible: Bool, animated: Bool) {
        guard visible != isOn else { return }
        isOn = visible

        if visible {
            if bulbLayers.isEmpty {
                rebuild()
            }
            layer?.removeAllAnimations()
            if animated {
                let animation = CABasicAnimation(keyPath: "opacity")
                animation.fromValue = layer?.presentation()?.opacity ?? 0
                animation.toValue = 1
                animation.duration = 0.7
                animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
                layer?.opacity = 1
                layer?.add(animation, forKey: "lightsFade")
            } else {
                layer?.opacity = 1
            }
        } else {
            layer?.removeAllAnimations()
            if animated {
                let animation = CABasicAnimation(keyPath: "opacity")
                animation.fromValue = layer?.presentation()?.opacity ?? 1
                animation.toValue = 0
                animation.duration = 0.55
                animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                layer?.opacity = 0
                layer?.add(animation, forKey: "lightsFade")

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
                    guard let self, self.isOn == false else { return }
                    self.clearContent()
                }
            } else {
                layer?.opacity = 0
                clearContent()
            }
        }
    }

    /// Change the colour and brightness of the whole garland.
    func applyCustomization(color: NSColor, brightness: CGFloat) {
        let newBrightness = min(max(brightness, 0.15), 1)
        guard color != baseColor || abs(newBrightness - self.brightness) > 0.001 else { return }

        baseColor = color
        self.brightness = newBrightness
        refreshBulbImages()

        // Keep the bulbs where they are so the garland doesn't jump around.
        for (index, bulb) in bulbLayers.enumerated() {
            let colorIndex = bulbColorIndices[index]
            bulb.contents = bulbImages[colorIndex]
        }

        wireLayer.shadowColor = Self.glowColor(for: baseColor)
            .withAlphaComponent(0.55 * brightness)
            .cgColor
    }

    private func refreshBulbImages() {
        let palette = Self.palette(for: baseColor)
        bulbImages = palette.map { Self.makeBulbImage(color: $0, brightness: brightness) }
        wireLayer.shadowColor = Self.glowColor(for: baseColor)
            .withAlphaComponent(0.55 * brightness)
            .cgColor
    }

    /// Builds a small family of shades around the chosen colour so the garland
    /// still looks like a string of mixed bulbs.
    private static func palette(for base: NSColor) -> [NSColor] {
        let rgb = base.usingColorSpace(.sRGB) ?? base
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var value: CGFloat = 0
        rgb.getHue(&hue, saturation: &saturation, brightness: &value, alpha: nil)

        func shade(hue: CGFloat, saturation: CGFloat, brightness: CGFloat) -> NSColor {
            NSColor(
                hue: hue.truncatingRemainder(dividingBy: 1),
                saturation: min(max(saturation, 0), 1),
                brightness: min(max(brightness, 0), 1),
                alpha: 1
            )
        }

        return [
            shade(hue: hue, saturation: saturation * 0.75, brightness: min(value * 1.05, 1)),
            shade(hue: hue, saturation: saturation * 0.35, brightness: min(value * 1.1 + 0.12, 1)),
            shade(hue: hue + 0.02, saturation: saturation, brightness: max(value * 0.8, 0.18)),
            shade(hue: hue + 0.07, saturation: min(saturation * 1.1, 1), brightness: max(value * 0.9, 0.18)),
            shade(hue: hue - 0.06, saturation: saturation * 0.9, brightness: max(value * 0.85, 0.18)),
            shade(hue: hue, saturation: saturation * 0.2, brightness: min(value + 0.25, 1))
        ]
    }

    private static func glowColor(for base: NSColor) -> NSColor {
        let rgb = base.usingColorSpace(.sRGB) ?? base
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var value: CGFloat = 0
        rgb.getHue(&hue, saturation: &saturation, brightness: &value, alpha: nil)
        return NSColor(
            hue: hue.truncatingRemainder(dividingBy: 1),
            saturation: min(saturation * 0.6, 1),
            brightness: min(max(value, 0.3), 1),
            alpha: 1
        )
    }

    // MARK: - Building the lights

    private enum Segment {
        case line(CGPoint, CGPoint, CGPoint)
        case arc(CGPoint, CGFloat, CGFloat, CGFloat)

        var length: CGFloat {
            switch self {
            case .line(let start, let end, _):
                return hypot(end.x - start.x, end.y - start.y)
            case .arc(_, let radius, let startAngle, let endAngle):
                return abs(endAngle - startAngle) * radius
            }
        }

        func point(at progress: CGFloat) -> (point: CGPoint, inward: CGPoint) {
            switch self {
            case .line(let start, let end, let inward):
                return (
                    CGPoint(
                        x: start.x + (end.x - start.x) * progress,
                        y: start.y + (end.y - start.y) * progress
                    ),
                    inward
                )
            case .arc(let center, let radius, let startAngle, let endAngle):
                let angle = startAngle + (endAngle - startAngle) * progress
                let point = CGPoint(
                    x: center.x + cos(angle) * radius,
                    y: center.y + sin(angle) * radius
                )
                let dx = center.x - point.x
                let dy = center.y - point.y
                let length = max(hypot(dx, dy), 0.001)
                return (point, CGPoint(x: dx / length, y: dy / length))
            }
        }
    }

    private struct WireSample {
        let point: CGPoint
        let inward: CGPoint
        let distance: CGFloat
    }

    private func clearContent() {
        for bulb in bulbLayers {
            bulb.removeFromSuperlayer()
        }
        bulbLayers.removeAll()
        bulbColorIndices.removeAll()
        wireLayer.path = nil
        lastBuiltSize = .zero
    }

    private func rebuild() {
        clearContent()
        guard bounds.width > 120, bounds.height > 120 else { return }

        let samples = makeWireSamples(step: 2)
        guard samples.count > 3 else { return }

        let path = CGMutablePath()
        path.move(to: samples[0].point)
        for sample in samples.dropFirst() {
            path.addLine(to: sample.point)
        }
        path.closeSubpath()

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        wireLayer.frame = bounds
        wireLayer.path = path
        CATransaction.commit()

        addBulbs(along: samples)
        lastBuiltSize = bounds.size
    }

    private func makeWireSamples(step: CGFloat) -> [WireSample] {
        let margin: CGFloat = 10
        let left = max(margin, insets.left + margin)
        let right = max(margin, insets.right + margin)
        let bottom = max(margin, insets.bottom + margin)
        let top = max(margin, insets.top + margin)

        let rect = CGRect(
            x: bounds.minX + left,
            y: bounds.minY + bottom,
            width: max(bounds.width - left - right, 1),
            height: max(bounds.height - top - bottom, 1)
        )
        let corner = min(30, min(rect.width, rect.height) * 0.18)

        let segments: [Segment] = [
            .line(
                CGPoint(x: rect.minX + corner, y: rect.maxY),
                CGPoint(x: rect.maxX - corner, y: rect.maxY),
                CGPoint(x: 0, y: -1)
            ),
            .arc(CGPoint(x: rect.maxX - corner, y: rect.maxY - corner), corner, .pi / 2, 0),
            .line(
                CGPoint(x: rect.maxX, y: rect.maxY - corner),
                CGPoint(x: rect.maxX, y: rect.minY + corner),
                CGPoint(x: -1, y: 0)
            ),
            .arc(CGPoint(x: rect.maxX - corner, y: rect.minY + corner), corner, 0, -.pi / 2),
            .line(
                CGPoint(x: rect.maxX - corner, y: rect.minY),
                CGPoint(x: rect.minX + corner, y: rect.minY),
                CGPoint(x: 0, y: 1)
            ),
            .arc(CGPoint(x: rect.minX + corner, y: rect.minY + corner), corner, -.pi / 2, -.pi),
            .line(
                CGPoint(x: rect.minX, y: rect.minY + corner),
                CGPoint(x: rect.minX, y: rect.maxY - corner),
                CGPoint(x: 1, y: 0)
            ),
            .arc(CGPoint(x: rect.minX + corner, y: rect.maxY - corner), corner, .pi, .pi / 2)
        ]

        let sagSpacing: CGFloat = 190
        let sagDepth: CGFloat = 9

        var samples: [WireSample] = []
        var traversed: CGFloat = 0

        for segment in segments {
            let length = segment.length
            guard length > 0 else { continue }

            var localDistance: CGFloat = 0
            while localDistance < length {
                let progress = localDistance / length
                let (base, inward) = segment.point(at: progress)

                let phase = (traversed + localDistance)
                    .truncatingRemainder(dividingBy: sagSpacing) / sagSpacing
                let sag = sin(phase * .pi) * sagDepth

                samples.append(WireSample(
                    point: CGPoint(
                        x: base.x + inward.x * sag,
                        y: base.y + inward.y * sag
                    ),
                    inward: inward,
                    distance: traversed + localDistance
                ))

                localDistance += step
            }

            traversed += length
        }

        return samples
    }

    private func addBulbs(along samples: [WireSample]) {
        let baseSpacing: CGFloat = 33
        var nextDistance: CGFloat = 16

        for sample in samples where sample.distance >= nextDistance {
            let colorIndex = randomColorIndex()
            let size = CGFloat.random(in: 15...24)
            let outwardOffset: CGFloat = CGFloat.random(in: 2.5...4.5)

            let bulb = CALayer()
            bulb.bounds = CGRect(x: 0, y: 0, width: size, height: size)
            bulb.position = CGPoint(
                x: sample.point.x + sample.inward.x * outwardOffset,
                y: sample.point.y + sample.inward.y * outwardOffset
            )
            bulb.contents = bulbImages[colorIndex]
            bulb.contentsScale = backingScale
            bulb.opacity = 0.95

            let duration = Double.random(in: 1.8...4.4)
            let twinkle = CABasicAnimation(keyPath: "opacity")
            twinkle.fromValue = 1.0
            twinkle.toValue = 0.42
            twinkle.duration = duration
            twinkle.autoreverses = true
            twinkle.repeatCount = .infinity
            twinkle.timeOffset = Double.random(in: 0...duration)
            twinkle.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            bulb.add(twinkle, forKey: "twinkle")

            layer?.addSublayer(bulb)
            bulbLayers.append(bulb)
            bulbColorIndices.append(colorIndex)

            nextDistance += baseSpacing * CGFloat.random(in: 0.85...1.15)
        }
    }

    private func randomColorIndex() -> Int {
        let roll = Int.random(in: 0..<100)
        switch roll {
        case 0..<40: return 0   // warm white
        case 40..<65: return 2  // gold
        case 65..<78: return 1  // soft white
        case 78..<89: return 3  // red
        case 89..<96: return 4  // green
        default: return 5       // ice blue
        }
    }

    private static func makeBulbImage(color: NSColor, brightness: CGFloat) -> CGImage {
        let pixelSize = 96
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let context = CGContext(
            data: nil,
            width: pixelSize,
            height: pixelSize,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!

        context.clear(CGRect(x: 0, y: 0, width: pixelSize, height: pixelSize))

        let converted = color.usingColorSpace(.sRGB) ?? color
        let red = converted.redComponent
        let green = converted.greenComponent
        let blue = converted.blueComponent
        let glow = min(max(brightness, 0.15), 1)

        let colors = [
            CGColor(colorSpace: colorSpace, components: [1, 1, 1, glow])!,
            CGColor(colorSpace: colorSpace, components: [red, green, blue, glow])!,
            CGColor(colorSpace: colorSpace, components: [red, green, blue, 0.55 * glow])!,
            CGColor(colorSpace: colorSpace, components: [red, green, blue, 0])!
        ] as CFArray
        let locations: [CGFloat] = [0, 0.10, 0.34, 1]

        let gradient = CGGradient(
            colorsSpace: colorSpace,
            colors: colors,
            locations: locations
        )!

        let center = CGPoint(x: CGFloat(pixelSize) / 2, y: CGFloat(pixelSize) / 2)
        context.drawRadialGradient(
            gradient,
            startCenter: center,
            startRadius: 0,
            endCenter: center,
            endRadius: CGFloat(pixelSize) / 2,
            options: []
        )

        return context.makeImage()!
    }
}
