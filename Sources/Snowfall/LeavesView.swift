import AppKit
import QuartzCore

/// Autumn leaf sprites drawn at runtime, then tinted by the emitter.
enum LeafTextures {
    private static let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    static let leaves: [CGImage] = [
        makeLeaf(style: 0),
        makeLeaf(style: 1),
        makeLeaf(style: 2)
    ]

    private static func makeContext(size: Int) -> CGContext? {
        guard let context = CGContext(
            data: nil,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.clear(CGRect(x: 0, y: 0, width: size, height: size))
        return context
    }

    private static func makeLeaf(style: Int) -> CGImage {
        let size = 128
        guard let context = makeContext(size: size), let image = drawLeaf(style: style, size: size, in: context) else {
            return CGImage.fallbackWhite(size: 8)
        }
        return image
    }

    private static func drawLeaf(style: Int, size: Int, in context: CGContext) -> CGImage? {
        let s = CGFloat(size)
        let center = CGPoint(x: s / 2, y: s / 2)
        let radius = s * 0.40

        let path = CGMutablePath()

        switch style {
        case 0:
            // A soft pointed leaf.
            path.move(to: CGPoint(x: center.x, y: center.y + radius))
            path.addCurve(
                to: CGPoint(x: center.x, y: center.y - radius),
                control1: CGPoint(x: center.x + radius * 1.15, y: center.y + radius * 0.35),
                control2: CGPoint(x: center.x + radius * 0.62, y: center.y - radius * 0.72)
            )
            path.addCurve(
                to: CGPoint(x: center.x, y: center.y + radius),
                control1: CGPoint(x: center.x - radius * 0.62, y: center.y - radius * 0.72),
                control2: CGPoint(x: center.x - radius * 1.15, y: center.y + radius * 0.35)
            )
        case 1:
            // A maple-ish leaf: five pointed lobes with deep valleys between them.
            let half: [(CGFloat, CGFloat)] = [
                (0.00, 1.00),
                (0.22, 0.60),
                (0.46, 0.86),
                (0.40, 0.38),
                (0.78, 0.50),
                (0.58, 0.08),
                (0.92, 0.04),
                (0.50, -0.28),
                (0.24, -0.18),
                (0.11, -0.60),
                (0.00, -0.78)
            ]
            let scale = radius / 1.05
            for (index, point) in half.enumerated() {
                let mapped = CGPoint(x: center.x + point.0 * scale, y: center.y + point.1 * scale)
                index == 0 ? path.move(to: mapped) : path.addLine(to: mapped)
            }
            for point in half.reversed().dropFirst().dropLast() {
                path.addLine(to: CGPoint(
                    x: center.x - point.0 * scale,
                    y: center.y + point.1 * scale
                ))
            }
            path.closeSubpath()
        default:
            // A rounded oak-ish leaf with gentle scallops.
            let steps = 220
            for index in 0...steps {
                let angle = CGFloat(index) / CGFloat(steps) * .pi * 2 - .pi / 2
                let scallop = 1 + 0.10 * sin(angle * 7)
                let squash = 0.75 + 0.25 * abs(sin(angle))
                let r = radius * scallop * squash
                let point = CGPoint(
                    x: center.x + cos(angle) * r * 0.68,
                    y: center.y + sin(angle) * r
                )
                index == 0 ? path.move(to: point) : path.addLine(to: point)
            }
            path.closeSubpath()
        }

        context.saveGState()
        context.setShadow(
            offset: CGSize(width: 0, height: -s * 0.015),
            blur: s * 0.03,
            color: NSColor.black.withAlphaComponent(0.28).cgColor
        )
        context.addPath(path)
        context.setFillColor(CGColor(colorSpace: colorSpace, components: [1, 1, 1, 1])!)
        context.fillPath()
        context.restoreGState()

        // A soft center vein so tinted leaves still show some detail.
        context.saveGState()
        context.addPath(path)
        context.clip()
        context.setStrokeColor(CGColor(colorSpace: colorSpace, components: [0.62, 0.50, 0.38, 0.55])!)
        context.setLineWidth(s * 0.018)
        context.setLineCap(.round)
        context.move(to: CGPoint(x: center.x, y: center.y + radius * 0.85))
        context.addLine(to: CGPoint(x: center.x, y: center.y - radius * 0.95))
        for offset in stride(from: -0.55, through: 0.55, by: 0.28) {
            let base = CGPoint(x: center.x, y: center.y + radius * CGFloat(offset))
            context.move(to: base)
            context.addLine(to: CGPoint(
                x: base.x + radius * 0.34,
                y: base.y + radius * 0.22
            ))
            context.move(to: base)
            context.addLine(to: CGPoint(
                x: base.x - radius * 0.34,
                y: base.y + radius * 0.22
            ))
        }
        context.strokePath()
        context.restoreGState()

        // Stem.
        context.setStrokeColor(CGColor(colorSpace: colorSpace, components: [0.78, 0.64, 0.48, 0.9])!)
        context.setLineWidth(s * 0.035)
        context.setLineCap(.round)
        context.move(to: CGPoint(x: center.x, y: center.y - radius * 0.9))
        context.addLine(to: CGPoint(x: center.x, y: center.y - radius * 1.18))
        context.strokePath()

        return context.makeImage()
    }
}

private extension CGImage {
    static func fallbackWhite(size: Int) -> CGImage {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let context = CGContext(
            data: nil,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(CGColor(colorSpace: colorSpace, components: [1, 1, 1, 1])!)
        context.fill(CGRect(x: 0, y: 0, width: size, height: size))
        return context.makeImage()!
    }
}

/// A transparent, non-interactive view full of drifting autumn leaves.
final class LeavesView: NSView {
    private let emitter = CAEmitterLayer()
    private let backingScale: CGFloat
    private var isVisible = false
    private var density: Double
    private var speed: Double

    private static let palette: [CGColor] = {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let colors: [(CGFloat, CGFloat, CGFloat)] = [
            (0.88, 0.44, 0.16), // orange
            (0.78, 0.20, 0.16), // red
            (0.93, 0.70, 0.20), // gold
            (0.62, 0.42, 0.18), // brown
            (0.86, 0.56, 0.20), // amber
            (0.70, 0.52, 0.12)  // ochre
        ]
        return colors.map { CGColor(colorSpace: colorSpace, components: [$0.0, $0.1, $0.2, 1])! }
    }()

    init(frame frameRect: NSRect, backingScale: CGFloat, density: Double = 0.5, speed: Double = 0.5) {
        self.backingScale = max(backingScale, 1)
        self.density = min(max(density, 0), 1)
        self.speed = min(max(speed, 0), 1)
        super.init(frame: frameRect)

        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.masksToBounds = false

        emitter.emitterShape = .rectangle
        emitter.emitterMode = .volume
        emitter.renderMode = .unordered
        emitter.contentsScale = backingScale
        emitter.opacity = 0
        layer?.addSublayer(emitter)

        updateGeometry()
        rebuildCells()
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
        updateGeometry()
        if isVisible {
            rebuildCells()
        }
    }

    func setLeavesVisible(_ visible: Bool, animated: Bool) {
        guard visible != isVisible else { return }
        isVisible = visible

        if animated {
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = emitter.presentation()?.opacity ?? (visible ? 0 : 1)
            animation.toValue = visible ? 1 : 0
            animation.duration = visible ? 0.8 : 0.55
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            emitter.opacity = visible ? 1 : 0
            emitter.add(animation, forKey: "leavesFade")
        } else {
            emitter.removeAllAnimations()
            emitter.opacity = visible ? 1 : 0
        }
    }

    /// Adjust how many leaves fall and how fast they blow past.
    func applyCustomization(density: Double, speed: Double) {
        let newDensity = min(max(density, 0), 1)
        let newSpeed = min(max(speed, 0), 1)
        guard abs(newDensity - self.density) > 0.001 || abs(newSpeed - self.speed) > 0.001 else { return }

        self.density = newDensity
        self.speed = newSpeed

        if isVisible {
            rebuildCells()
        }
    }

    private func updateGeometry() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        emitter.frame = bounds
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: bounds.maxY + 10)
        emitter.emitterSize = CGSize(width: max(bounds.width, 1) * 1.08, height: 40)
        CATransaction.commit()
    }

    private func rebuildCells() {
        let area = max(bounds.width * bounds.height, 1)
        let displayFactor = Double(area / (1920 * 1080))
        let densityFactor = 0.2 + 1.8 * density
        let speedFactor = 0.45 + 1.55 * speed
        let totalLeaves = 64 * displayFactor * densityFactor
        let meanLifetime: Double = 26
        let totalBirthRate = totalLeaves / meanLifetime

        var cells: [CAEmitterCell] = []
        let styleCount = LeafTextures.leaves.count
        let colorCount = Self.palette.count
        let combinations = styleCount * colorCount

        for style in 0..<styleCount {
            for colorIndex in 0..<colorCount {
                let cell = CAEmitterCell()
                cell.contents = LeafTextures.leaves[style]
                cell.contentsScale = 2
                cell.birthRate = Float(totalBirthRate / Double(combinations))
                cell.lifetime = Float(meanLifetime)
                cell.lifetimeRange = 10

                cell.velocity = CGFloat.random(in: 16...30) * CGFloat(speedFactor)
                cell.velocityRange = 12 * CGFloat(speedFactor)
                cell.emissionLongitude = -CGFloat.pi / 2
                cell.emissionRange = .pi / 4

                let scale = CGFloat.random(in: 0.10...0.22)
                cell.scale = scale
                cell.scaleRange = 0.06
                cell.scaleSpeed = -0.0015

                cell.color = Self.palette[colorIndex]
                cell.alphaRange = 0.25
                cell.alphaSpeed = -1 / Float(meanLifetime)

                cell.spin = CGFloat.random(in: 0.6...1.8) * (Bool.random() ? 1 : -1) * CGFloat(speedFactor)
                cell.spinRange = 1.2
                cell.yAcceleration = -3 * CGFloat(speedFactor)
                cell.xAcceleration = CGFloat.random(in: -5...5) * CGFloat(speedFactor)

                // Leaves span the full height so the screen never looks empty
                // right after the effect is turned on.
                cell.lifetimeRange = 10
                cells.append(cell)
            }
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        emitter.emitterCells = cells
        CATransaction.commit()
    }
}
