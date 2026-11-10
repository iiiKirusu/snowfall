import AppKit
import Darwin

// Usage: swift Scripts/generate-icon.swift <output.iconset>

guard CommandLine.arguments.count >= 2 else {
    FileHandle.standardError.write(Data("usage: generate-icon.swift <output.iconset>\n".utf8))
    exit(1)
}

let outputDirectory = CommandLine.arguments[1]
try FileManager.default.createDirectory(atPath: outputDirectory, withIntermediateDirectories: true)

let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

extension NSBezierPath {
    var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [NSPoint](repeating: .zero, count: 3)
        for index in 0..<elementCount {
            switch element(at: index, associatedPoints: &points) {
            case .moveTo:
                path.move(to: points[0])
            case .lineTo:
                path.addLine(to: points[0])
            case .curveTo, .cubicCurveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .quadraticCurveTo:
                path.addQuadCurve(to: points[1], control: points[0])
            case .closePath:
                path.closeSubpath()
            @unknown default:
                break
            }
        }
        return path
    }
}

struct Star {
    let x: CGFloat
    let y: CGFloat
    let radius: CGFloat
    let alpha: CGFloat
}

srand48(20261225)
let stars: [Star] = (0..<30).map { _ in
    Star(
        x: CGFloat(drand48()),
        y: CGFloat(drand48()),
        radius: CGFloat(drand48()) * 0.006 + 0.0012,
        alpha: CGFloat(drand48()) * 0.55 + 0.15
    )
}

func render(size: Int) -> Data? {
    guard let representation = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { return nil }

    representation.size = NSSize(width: size, height: size)

    guard let graphicsContext = NSGraphicsContext(bitmapImageRep: representation) else {
        return nil
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphicsContext

    let cg = graphicsContext.cgContext
    let s = CGFloat(size)
    let inset = s * 0.06
    let rect = CGRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let radius = s * 0.225
    let background = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)

    // Soft drop shadow behind the rounded tile.
    cg.saveGState()
    cg.addPath(background)
    cg.setShadow(
        offset: CGSize(width: 0, height: -s * 0.012),
        blur: s * 0.035,
        color: NSColor.black.withAlphaComponent(0.35).cgColor
    )
    cg.setFillColor(CGColor(colorSpace: colorSpace, components: [0.03, 0.05, 0.13, 1])!)
    cg.fillPath()
    cg.restoreGState()

    // Night sky gradient.
    cg.saveGState()
    cg.addPath(background)
    cg.clip()

    let skyColors = [
        CGColor(colorSpace: colorSpace, components: [0.045, 0.07, 0.17, 1])!,
        CGColor(colorSpace: colorSpace, components: [0.09, 0.13, 0.33, 1])!,
        CGColor(colorSpace: colorSpace, components: [0.18, 0.21, 0.49, 1])!
    ] as CFArray
    if let sky = CGGradient(colorsSpace: colorSpace, colors: skyColors, locations: [0, 0.55, 1]) {
        cg.drawLinearGradient(
            sky,
            start: CGPoint(x: 0, y: rect.minY),
            end: CGPoint(x: 0, y: rect.maxY),
            options: []
        )
    }

    // Aurora glow in the top-right corner.
    let glowColors = [
        CGColor(colorSpace: colorSpace, components: [0.20, 0.80, 0.68, 0.30])!,
        CGColor(colorSpace: colorSpace, components: [0.20, 0.80, 0.68, 0])!
    ] as CFArray
    if let glow = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0, 1]) {
        let center = CGPoint(x: rect.maxX * 0.82, y: rect.maxY * 0.86)
        cg.drawRadialGradient(
            glow,
            startCenter: center,
            startRadius: 0,
            endCenter: center,
            endRadius: s * 0.5,
            options: []
        )
    }

    // Stars.
    for star in stars {
        let x = rect.minX + inset * 0.5 + star.x * (rect.width - inset)
        let y = rect.minY + inset * 0.5 + star.y * (rect.height - inset)
        cg.setFillColor(CGColor(colorSpace: colorSpace, components: [1, 1, 1, star.alpha])!)
        let r = star.radius * s
        cg.fillEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
    }

    // Snowflake.
    let center = CGPoint(x: s * 0.5, y: s * 0.51)
    let armLength = s * 0.285
    let lineWidth = s * 0.043
    let flake = CGMutablePath()

    for armIndex in 0..<6 {
        let angle = CGFloat(armIndex) * .pi / 3 + .pi / 2
        let tip = CGPoint(
            x: center.x + cos(angle) * armLength,
            y: center.y + sin(angle) * armLength
        )
        flake.move(to: center)
        flake.addLine(to: tip)

        for branchPosition: CGFloat in [0.46, 0.74] {
            let base = CGPoint(
                x: center.x + cos(angle) * armLength * branchPosition,
                y: center.y + sin(angle) * armLength * branchPosition
            )
            let branchLength = armLength * (branchPosition < 0.6 ? 0.28 : 0.18)
            for direction: CGFloat in [-1, 1] {
                let branchAngle = angle + direction * .pi / 4.2
                flake.move(to: base)
                flake.addLine(to: CGPoint(
                    x: base.x + cos(branchAngle) * branchLength,
                    y: base.y + sin(branchAngle) * branchLength
                ))
            }
        }
    }

    cg.saveGState()
    cg.setShadow(
        offset: .zero,
        blur: s * 0.035,
        color: CGColor(colorSpace: colorSpace, components: [0.55, 0.78, 1, 0.9])!
    )
    cg.addPath(flake)
    cg.setStrokeColor(CGColor(colorSpace: colorSpace, components: [0.94, 0.97, 1, 1])!)
    cg.setLineWidth(lineWidth)
    cg.setLineCap(.round)
    cg.setLineJoin(.round)
    cg.strokePath()
    cg.restoreGState()

    // Twinkly dots at the center and tips.
    cg.setFillColor(CGColor(colorSpace: colorSpace, components: [1, 1, 1, 1])!)
    let centerDot = lineWidth * 0.9
    cg.fillEllipse(in: CGRect(
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
        let dot = lineWidth * 0.7
        cg.fillEllipse(in: CGRect(
            x: tip.x - dot / 2,
            y: tip.y - dot / 2,
            width: dot,
            height: dot
        ))
    }

    // A few little falling flakes for extra charm.
    let dust: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
        (0.26, 0.24, 0.012, 0.85),
        (0.74, 0.31, 0.010, 0.70),
        (0.20, 0.62, 0.008, 0.55),
        (0.81, 0.60, 0.009, 0.60),
        (0.63, 0.13, 0.007, 0.50),
        (0.37, 0.86, 0.008, 0.45)
    ]
    for (dx, dy, dr, alpha) in dust {
        cg.setFillColor(CGColor(colorSpace: colorSpace, components: [1, 1, 1, alpha])!)
        let r = s * dr
        cg.fillEllipse(in: CGRect(x: s * dx - r, y: s * dy - r, width: r * 2, height: r * 2))
    }

    cg.restoreGState()

    NSGraphicsContext.restoreGraphicsState()
    return representation.representation(using: .png, properties: [:])
}

let variants: [(size: Int, names: [String])] = [
    (16, ["icon_16x16.png"]),
    (32, ["icon_16x16@2x.png", "icon_32x32.png"]),
    (64, ["icon_32x32@2x.png"]),
    (128, ["icon_128x128.png"]),
    (256, ["icon_128x128@2x.png", "icon_256x256.png"]),
    (512, ["icon_256x256@2x.png", "icon_512x512.png"]),
    (1024, ["icon_512x512@2x.png"])
]

let baseURL = URL(fileURLWithPath: outputDirectory)

for variant in variants {
    guard let data = render(size: variant.size) else {
        FileHandle.standardError.write(Data("Failed to render icon at \(variant.size)px\n".utf8))
        exit(1)
    }
    for name in variant.names {
        try data.write(to: baseURL.appendingPathComponent(name))
    }
}
