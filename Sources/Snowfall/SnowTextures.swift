import AppKit
import CoreGraphics

/// Draws the tiny snowflake and soft dot sprites used by the particle system.
/// Drawing them ourselves keeps the app self-contained and crisp on Retina displays.
enum SnowTextures {
    static let softDot = makeSoftDot(size: 64)
    static let flake = makeFlake(size: 128)

    private static let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

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

    private static func makeSoftDot(size: Int) -> CGImage {
        guard let context = makeContext(size: size) else {
            return fallbackImage()
        }

        let center = CGPoint(x: CGFloat(size) / 2, y: CGFloat(size) / 2)
        let radius = CGFloat(size) / 2
        let colors = [
            CGColor(colorSpace: colorSpace, components: [1, 1, 1, 1])!,
            CGColor(colorSpace: colorSpace, components: [1, 1, 1, 0.55])!,
            CGColor(colorSpace: colorSpace, components: [1, 1, 1, 0])!
        ] as CFArray
        let locations: [CGFloat] = [0, 0.4, 1]

        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) else {
            return fallbackImage()
        }

        context.drawRadialGradient(
            gradient,
            startCenter: center,
            startRadius: 0,
            endCenter: center,
            endRadius: radius,
            options: []
        )

        return context.makeImage() ?? fallbackImage()
    }

    private static func makeFlake(size: Int) -> CGImage {
        guard let context = makeContext(size: size) else {
            return fallbackImage()
        }

        let s = CGFloat(size)
        let center = CGPoint(x: s / 2, y: s / 2)
        let armLength = s * 0.41
        let lineWidth = s * 0.05

        // Soft halo so flakes stay visible on both dark and light wallpapers.
        let haloColors = [
            CGColor(colorSpace: colorSpace, components: [0.75, 0.88, 1, 0.22])!,
            CGColor(colorSpace: colorSpace, components: [0.75, 0.88, 1, 0])!
        ] as CFArray
        if let halo = CGGradient(colorsSpace: colorSpace, colors: haloColors, locations: [0, 1]) {
            context.drawRadialGradient(
                halo,
                startCenter: center,
                startRadius: 0,
                endCenter: center,
                endRadius: s * 0.48,
                options: []
            )
        }

        let path = CGMutablePath()

        for armIndex in 0..<6 {
            let angle = CGFloat(armIndex) * .pi / 3 + .pi / 2
            let tip = CGPoint(
                x: center.x + cos(angle) * armLength,
                y: center.y + sin(angle) * armLength
            )
            path.move(to: center)
            path.addLine(to: tip)

            for branchPosition: CGFloat in [0.48, 0.78] {
                let base = CGPoint(
                    x: center.x + cos(angle) * armLength * branchPosition,
                    y: center.y + sin(angle) * armLength * branchPosition
                )
                let branchLength = armLength * (branchPosition < 0.6 ? 0.26 : 0.17)
                for direction: CGFloat in [-1, 1] {
                    let branchAngle = angle + direction * .pi / 4.2
                    path.move(to: base)
                    path.addLine(to: CGPoint(
                        x: base.x + cos(branchAngle) * branchLength,
                        y: base.y + sin(branchAngle) * branchLength
                    ))
                }
            }
        }

        context.saveGState()
        context.setShadow(
            offset: CGSize(width: 0, height: -s * 0.018),
            blur: s * 0.045,
            color: NSColor.black.withAlphaComponent(0.30).cgColor
        )
        context.addPath(path)
        context.setStrokeColor(CGColor(colorSpace: colorSpace, components: [0.96, 0.98, 1, 0.97])!)
        context.setLineWidth(lineWidth)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.strokePath()
        context.restoreGState()

        // Little dots at the tips and the center give it a twinkly feel.
        context.setFillColor(CGColor(colorSpace: colorSpace, components: [0.98, 0.99, 1, 1])!)
        let centerDot = lineWidth * 0.95
        context.fillEllipse(in: CGRect(
            x: center.x - centerDot / 2,
            y: center.y - centerDot / 2,
            width: centerDot,
            height: centerDot
        ))

        for armIndex in 0..<6 {
            let angle = CGFloat(armIndex) * .pi / 3 + .pi / 2
            let tip = CGPoint(
                x: center.x + cos(angle) * armLength,
                y: center.y + sin(angle) * armLength
            )
            let dot = lineWidth * 0.75
            context.fillEllipse(in: CGRect(
                x: tip.x - dot / 2,
                y: tip.y - dot / 2,
                width: dot,
                height: dot
            ))
        }

        return context.makeImage() ?? fallbackImage()
    }

    private static func fallbackImage() -> CGImage {
        let context = CGContext(
            data: nil,
            width: 2,
            height: 2,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(CGColor(colorSpace: colorSpace, components: [1, 1, 1, 1])!)
        context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        return context.makeImage()!
    }
}
