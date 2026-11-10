import AppKit
import QuartzCore

/// A transparent, non-interactive view that renders two layers of drifting snow.
final class SnowView: NSView {
    private let farLayer = CAEmitterLayer()
    private let nearLayer = CAEmitterLayer()
    private let backingScale: CGFloat
    private var intensity: Intensity
    private var isVisible = false

    private struct CellSpec {
        let image: CGImage
        let share: Double
        let scale: ClosedRange<CGFloat>
        let alpha: CGFloat
        let speed: ClosedRange<CGFloat>
        let lifetime: ClosedRange<CGFloat>
        let drift: CGFloat
        let spin: CGFloat
    }

    private let farSpecs: [CellSpec] = [
        CellSpec(
            image: SnowTextures.softDot,
            share: 0.62,
            scale: 0.07...0.14,
            alpha: 0.55,
            speed: 10...26,
            lifetime: 16...26,
            drift: 2.5,
            spin: 0.04
        ),
        CellSpec(
            image: SnowTextures.softDot,
            share: 0.38,
            scale: 0.12...0.20,
            alpha: 0.38,
            speed: 14...32,
            lifetime: 18...28,
            drift: 4,
            spin: 0.04
        )
    ]

    private let nearSpecs: [CellSpec] = [
        CellSpec(
            image: SnowTextures.flake,
            share: 0.63,
            scale: 0.12...0.21,
            alpha: 0.88,
            speed: 32...56,
            lifetime: 15...23,
            drift: 6,
            spin: 0.35
        ),
        CellSpec(
            image: SnowTextures.flake,
            share: 0.37,
            scale: 0.21...0.34,
            alpha: 0.95,
            speed: 48...74,
            lifetime: 13...19,
            drift: 8,
            spin: 0.28
        )
    ]

    init(frame frameRect: NSRect, intensity: Intensity, backingScale: CGFloat) {
        self.intensity = intensity
        self.backingScale = backingScale
        super.init(frame: frameRect)

        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.masksToBounds = false

        setUpLayers()
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
    }

    func applyIntensity(_ newIntensity: Intensity) {
        guard newIntensity != intensity else { return }
        intensity = newIntensity
        rebuildCells()
    }

    func setSnowVisible(_ visible: Bool, animated: Bool) {
        guard visible != isVisible else { return }
        isVisible = visible

        if animated {
            visible ? fadeIn() : fadeOut()
        } else {
            for emitter in [farLayer, nearLayer] {
                emitter.removeAllAnimations()
                emitter.opacity = visible ? 1 : 0
            }
        }
    }

    private func fadeIn() {
        for emitter in [farLayer, nearLayer] {
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = 0
            animation.toValue = 1
            animation.duration = 0.9
            animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            emitter.opacity = 1
            emitter.add(animation, forKey: "fadeIn")
        }
    }

    private func fadeOut() {
        for emitter in [farLayer, nearLayer] {
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = 1
            animation.toValue = 0
            animation.duration = 0.55
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            emitter.opacity = 0
            emitter.add(animation, forKey: "fadeOut")
        }
    }

    private func setUpLayers() {
        let emitters: [(CAEmitterLayer, CGFloat)] = [(farLayer, 0), (nearLayer, 1)]

        for (emitter, zPosition) in emitters {
            emitter.emitterShape = .rectangle
            emitter.emitterMode = .volume
            emitter.renderMode = .unordered
            emitter.contentsScale = backingScale
            emitter.opacity = 0
            emitter.zPosition = zPosition
            layer?.addSublayer(emitter)
        }
    }

    private func updateGeometry() {
        let bounds = self.bounds

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for emitter in [farLayer, nearLayer] {
            emitter.frame = bounds
            emitter.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
            emitter.emitterSize = CGSize(
                width: max(bounds.width, 1) * 1.02,
                height: max(bounds.height, 1) * 1.02
            )
        }
        CATransaction.commit()
    }

    private func rebuildCells() {
        let area = max(bounds.width * bounds.height, 1)
        let displayFactor = Double(area / (1920 * 1080))
        let total = intensity.targetCount * displayFactor

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        farLayer.emitterCells = makeCells(count: total * 0.65, specs: farSpecs)
        nearLayer.emitterCells = makeCells(count: total * 0.35, specs: nearSpecs)
        CATransaction.commit()
    }

    private func makeCells(count: Double, specs: [CellSpec]) -> [CAEmitterCell] {
        specs.map { spec in
            let meanLifetime = Double((spec.lifetime.lowerBound + spec.lifetime.upperBound) / 2)
            let birthRate = Float(count * spec.share / max(meanLifetime, 1))
            return makeCell(from: spec, birthRate: birthRate)
        }
    }

    private func makeCell(from spec: CellSpec, birthRate: Float) -> CAEmitterCell {
        let cell = CAEmitterCell()
        let meanLifetime = (spec.lifetime.lowerBound + spec.lifetime.upperBound) / 2
        let meanScale = (spec.scale.lowerBound + spec.scale.upperBound) / 2
        let meanSpeed = (spec.speed.lowerBound + spec.speed.upperBound) / 2

        cell.contents = spec.image
        cell.contentsScale = 2
        cell.birthRate = max(birthRate, 0.1)
        cell.lifetime = Float(meanLifetime)
        cell.lifetimeRange = Float((spec.lifetime.upperBound - spec.lifetime.lowerBound) / 2)

        cell.velocity = meanSpeed
        cell.velocityRange = (spec.speed.upperBound - spec.speed.lowerBound) / 2
        cell.emissionLongitude = -CGFloat.pi / 2
        cell.emissionRange = .pi / 5

        cell.scale = meanScale
        cell.scaleRange = (spec.scale.upperBound - spec.scale.lowerBound) / 2
        cell.scaleSpeed = -0.002

        cell.alphaRange = 0.15
        cell.alphaSpeed = Float(-spec.alpha / max(meanLifetime * 0.9, 0.1))
        cell.color = CGColor(gray: 1, alpha: spec.alpha)

        cell.spin = spec.spin
        cell.spinRange = spec.spin * 2
        cell.yAcceleration = -1.5
        cell.xAcceleration = CGFloat.random(in: -spec.drift...spec.drift)

        return cell
    }
}
