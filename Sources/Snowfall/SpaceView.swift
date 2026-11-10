import AppKit
import QuartzCore

/// Sprites for the space theme: a twinkling star and a shooting-star streak.
private enum SpaceTextures {
    private static let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

    static let sparkle: CGImage = {
        let size = 64
        guard let context = CGContext(
            data: nil,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return CGImage.spaceFallback(size: 8)
        }

        context.clear(CGRect(x: 0, y: 0, width: size, height: size))
        let center = CGPoint(x: CGFloat(size) / 2, y: CGFloat(size) / 2)

        let colors = [
            CGColor(colorSpace: colorSpace, components: [1, 1, 1, 0.95])!,
            CGColor(colorSpace: colorSpace, components: [0.72, 0.86, 1, 0.45])!,
            CGColor(colorSpace: colorSpace, components: [0.60, 0.75, 1, 0])!
        ] as CFArray
        if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 0.28, 1]) {
            context.drawRadialGradient(
                gradient,
                startCenter: center,
                startRadius: 0,
                endCenter: center,
                endRadius: CGFloat(size) / 2,
                options: []
            )
        }

        // Four-point flare.
        context.setStrokeColor(CGColor(colorSpace: colorSpace, components: [1, 1, 1, 0.85])!)
        context.setLineWidth(1.2)
        context.setLineCap(.round)
        context.move(to: CGPoint(x: center.x - CGFloat(size) * 0.46, y: center.y))
        context.addLine(to: CGPoint(x: center.x + CGFloat(size) * 0.46, y: center.y))
        context.move(to: CGPoint(x: center.x, y: center.y - CGFloat(size) * 0.46))
        context.addLine(to: CGPoint(x: center.x, y: center.y + CGFloat(size) * 0.46))
        context.strokePath()

        return context.makeImage() ?? CGImage.spaceFallback(size: 8)
    }()

    static let shootingStar: CGImage = {
        let width = 320
        let height = 24
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return CGImage.spaceFallback(size: 8)
        }

        context.clear(CGRect(x: 0, y: 0, width: width, height: height))

        let colors = [
            CGColor(colorSpace: colorSpace, components: [0.75, 0.88, 1, 0])!,
            CGColor(colorSpace: colorSpace, components: [0.85, 0.93, 1, 0.12])!,
            CGColor(colorSpace: colorSpace, components: [1, 1, 1, 0.85])!,
            CGColor(colorSpace: colorSpace, components: [1, 1, 1, 1])!
        ] as CFArray
        if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 0.55, 0.94, 1]) {
            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: CGFloat(height) / 2),
                end: CGPoint(x: CGFloat(width), y: CGFloat(height) / 2),
                options: []
            )
        }

        let headCenter = CGPoint(x: CGFloat(width) - 8, y: CGFloat(height) / 2)
        let headColors = [
            CGColor(colorSpace: colorSpace, components: [1, 1, 1, 1])!,
            CGColor(colorSpace: colorSpace, components: [0.8, 0.9, 1, 0])!
        ] as CFArray
        if let glow = CGGradient(colorsSpace: colorSpace, colors: headColors, locations: [0, 1]) {
            context.drawRadialGradient(
                glow,
                startCenter: headCenter,
                startRadius: 0,
                endCenter: headCenter,
                endRadius: 12,
                options: []
            )
        }

        return context.makeImage() ?? CGImage.spaceFallback(size: 8)
    }()

    /// A deep-space starfield with a few soft nebula clouds and a handful of
    /// brighter stars. Drawn at the display's pixel size so it stays crisp.
    static func makeStarfield(pixelWidth: Int, pixelHeight: Int) -> CGImage {
        guard let context = CGContext(
            data: nil,
            width: pixelWidth,
            height: pixelHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return CGImage.spaceFallback(size: 8)
        }

        let bounds = CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight)
        context.clear(bounds)

        let width = CGFloat(pixelWidth)
        let height = CGFloat(pixelHeight)

        // Soft nebula wash.
        let nebulae: [(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (0.28, 0.72, 0.38, 0.70, 0.82, 0.18),
            (0.68, 0.58, 0.42, 0.55, 0.35, 0.16),
            (0.50, 0.30, 0.30, 0.26, 0.40, 0.12)
        ]
        for nebula in nebulae {
            let center = CGPoint(x: width * nebula.0, y: height * nebula.1)
            let radius = max(width, height) * nebula.2
            let colors = [
                CGColor(colorSpace: colorSpace, components: [nebula.4, nebula.5, 0.95, nebula.3])!,
                CGColor(colorSpace: colorSpace, components: [nebula.4, nebula.5, 0.95, 0])!
            ] as CFArray
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1]) {
                context.drawRadialGradient(
                    gradient,
                    startCenter: center,
                    startRadius: 0,
                    endCenter: center,
                    endRadius: radius,
                    options: []
                )
            }
        }

        let starCount = max(Int(Double(pixelWidth * pixelHeight) / 4200), 160)
        for _ in 0..<starCount {
            let x = CGFloat.random(in: 0...width)
            let y = CGFloat.random(in: 0...height)
            let radius = CGFloat.random(in: 0.45...1.9)
            let alpha = CGFloat.random(in: 0.28...1.0)

            let warmth = CGFloat.random(in: 0...1)
            let red = 0.82 + warmth * 0.18
            let green = 0.88 + warmth * 0.10
            let blue = 1.0 - warmth * 0.10

            context.setFillColor(CGColor(colorSpace: colorSpace, components: [red, green, blue, alpha])!)
            context.fillEllipse(in: CGRect(
                x: x - radius,
                y: y - radius,
                width: radius * 2,
                height: radius * 2
            ))

            // A few stars get a soft halo.
            if Bool.random() && Bool.random() {
                let halo = [
                    CGColor(colorSpace: colorSpace, components: [red, green, blue, alpha * 0.45])!,
                    CGColor(colorSpace: colorSpace, components: [red, green, blue, 0])!
                ] as CFArray
                if let gradient = CGGradient(colorsSpace: colorSpace, colors: halo, locations: [0, 1]) {
                    context.drawRadialGradient(
                        gradient,
                        startCenter: CGPoint(x: x, y: y),
                        startRadius: 0,
                        endCenter: CGPoint(x: x, y: y),
                        endRadius: radius * 4.5,
                        options: []
                    )
                }
            }
        }

        return context.makeImage() ?? CGImage.spaceFallback(size: 8)
    }
}

private extension CGImage {
    static func spaceFallback(size: Int) -> CGImage {
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

/// A deep-space theme: a dark blue night sky, twinkling stars, and the
/// occasional shooting star. A subtle overlay keeps the wallpaper visible.
final class SpaceView: NSView {
    private let backingScale: CGFloat
    private let backgroundLayer = CAGradientLayer()
    private let starfieldLayer = CALayer()
    private let sparkleLayer = CALayer()
    private let shootingLayer = CALayer()

    private var sparkles: [CALayer] = []
    private var isVisible = false
    private var timer: Timer?
    private var nextShoot: TimeInterval = 0
    private var lastBuiltSize: NSSize = .zero

    init(frame frameRect: NSRect, backingScale: CGFloat) {
        self.backingScale = max(backingScale, 1)
        super.init(frame: frameRect)

        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.masksToBounds = false
        layer?.opacity = 0

        backgroundLayer.startPoint = CGPoint(x: 0.5, y: 1)
        backgroundLayer.endPoint = CGPoint(x: 0.5, y: 0)
        backgroundLayer.colors = [
            NSColor(calibratedRed: 0.015, green: 0.025, blue: 0.075, alpha: 0.68).cgColor,
            NSColor(calibratedRed: 0.035, green: 0.055, blue: 0.145, alpha: 0.42).cgColor,
            NSColor(calibratedRed: 0.010, green: 0.015, blue: 0.045, alpha: 0.58).cgColor
        ]
        backgroundLayer.locations = [0, 0.55, 1]

        starfieldLayer.contentsScale = backingScale
        sparkleLayer.contentsScale = backingScale
        shootingLayer.contentsScale = backingScale

        layer?.addSublayer(backgroundLayer)
        layer?.addSublayer(starfieldLayer)
        layer?.addSublayer(sparkleLayer)
        layer?.addSublayer(shootingLayer)

        updateGeometry()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        timer?.invalidate()
    }

    override var isOpaque: Bool { false }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        updateGeometry()
        if isVisible {
            buildIfNeeded(force: true)
        }
    }

    func setSpaceVisible(_ visible: Bool, animated: Bool) {
        guard visible != isVisible else { return }
        isVisible = visible

        if visible {
            buildIfNeeded(force: false)
            startTimer()
        } else {
            stopTimer()
            removeShootingStars()
        }

        if animated {
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = layer?.presentation()?.opacity ?? (visible ? 0 : 1)
            animation.toValue = visible ? 1 : 0
            animation.duration = visible ? 1.1 : 0.6
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            layer?.opacity = visible ? 1 : 0
            layer?.add(animation, forKey: "spaceFade")
        } else {
            layer?.removeAllAnimations()
            layer?.opacity = visible ? 1 : 0
        }
    }

    private func updateGeometry() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        backgroundLayer.frame = bounds
        starfieldLayer.frame = bounds
        sparkleLayer.frame = bounds
        shootingLayer.frame = bounds
        CATransaction.commit()
    }

    private func buildIfNeeded(force: Bool) {
        let size = bounds.size
        guard size.width > 2, size.height > 2 else { return }
        if !force, starfieldLayer.contents != nil, lastBuiltSize == size {
            return
        }
        lastBuiltSize = size

        let pixelWidth = max(Int((size.width * backingScale).rounded()), 2)
        let pixelHeight = max(Int((size.height * backingScale).rounded()), 2)
        let image = SpaceTextures.makeStarfield(pixelWidth: pixelWidth, pixelHeight: pixelHeight)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        starfieldLayer.contents = image
        starfieldLayer.contentsScale = backingScale
        backgroundLayer.frame = bounds
        starfieldLayer.frame = bounds
        sparkleLayer.frame = bounds
        shootingLayer.frame = bounds
        buildSparkles()
        CATransaction.commit()
    }

    private func buildSparkles() {
        for sparkle in sparkles {
            sparkle.removeFromSuperlayer()
        }
        sparkles.removeAll()

        guard bounds.width > 2, bounds.height > 2 else { return }

        let count = max(Int(Double(bounds.width * bounds.height) / 34000), 30)
        for _ in 0..<count {
            let layer = CALayer()
            let size = CGFloat.random(in: 8...22)
            layer.bounds = CGRect(x: 0, y: 0, width: size, height: size)
            layer.position = CGPoint(
                x: CGFloat.random(in: 0...bounds.width),
                y: CGFloat.random(in: 0...bounds.height)
            )
            layer.contents = SpaceTextures.sparkle
            layer.contentsScale = backingScale
            layer.opacity = 0

            let duration = Double.random(in: 1.6...4.8)
            let twinkle = CABasicAnimation(keyPath: "opacity")
            twinkle.fromValue = CGFloat.random(in: 0.85...1.0)
            twinkle.toValue = CGFloat.random(in: 0.12...0.35)
            twinkle.duration = duration
            twinkle.autoreverses = true
            twinkle.repeatCount = .infinity
            twinkle.timeOffset = Double.random(in: 0...duration)
            twinkle.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            layer.add(twinkle, forKey: "twinkle")

            sparkleLayer.addSublayer(layer)
            sparkles.append(layer)
        }
    }

    // MARK: - Shooting stars

    private func startTimer() {
        guard timer == nil else { return }
        nextShoot = Date().timeIntervalSinceReferenceDate + Double.random(in: 1.2...3.5)

        let timer = Timer(timeInterval: 0.4, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard isVisible, layer?.opacity ?? 0 > 0.01 else { return }
        let now = Date().timeIntervalSinceReferenceDate
        guard now >= nextShoot else { return }
        nextShoot = now + Double.random(in: 3.5...8.5)
        shoot()
    }

    private func shoot() {
        guard bounds.width > 100, bounds.height > 100 else { return }

        let startX = CGFloat.random(in: bounds.width * 0.12...bounds.width * 0.88)
        let startY = CGFloat.random(in: bounds.height * 0.55...bounds.height * 0.95)
        let direction: CGFloat = Bool.random() ? -1 : 1
        let distance = min(bounds.width, bounds.height) * CGFloat.random(in: 0.35...0.62)
        let angle = CGFloat.random(in: 0.35...0.75) * direction
        let endX = startX + sin(angle) * distance * 1.4
        let endY = startY - cos(angle) * distance

        let streak = CALayer()
        streak.bounds = CGRect(x: 0, y: 0, width: 160, height: 12)
        streak.contents = SpaceTextures.shootingStar
        streak.contentsScale = backingScale
        streak.position = CGPoint(x: startX, y: startY)
        streak.opacity = 0
        streak.setAffineTransform(CGAffineTransform(rotationAngle: atan2(endY - startY, endX - startX)))
        shootingLayer.addSublayer(streak)

        let duration = Double.random(in: 0.8...1.4)

        let move = CABasicAnimation(keyPath: "position")
        move.fromValue = NSValue(point: CGPoint(x: startX, y: startY))
        move.toValue = NSValue(point: CGPoint(x: endX, y: endY))

        let fade = CAKeyframeAnimation(keyPath: "opacity")
        fade.values = [0, 1, 1, 0]
        fade.keyTimes = [0, 0.12, 0.7, 1]

        let group = CAAnimationGroup()
        group.animations = [move, fade]
        group.duration = duration
        group.timingFunction = CAMediaTimingFunction(name: .easeOut)
        streak.add(group, forKey: "shoot")

        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.2) { [weak streak] in
            streak?.removeFromSuperlayer()
        }
    }

    private func removeShootingStars() {
        shootingLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
    }
}
