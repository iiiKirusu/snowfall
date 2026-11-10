import AppKit

/// A small window for tuning the autumn leaves and the Christmas lights.
/// Every change is applied live, straight onto the desktop.
final class AtmosphereController: NSObject, NSWindowDelegate {
    private let window: NSWindow

    private let leavesDensitySlider = NSSlider(value: 0.5, minValue: 0, maxValue: 1, target: nil, action: nil)
    private let leavesDensityLabel = NSTextField(labelWithString: "")
    private let leavesSpeedSlider = NSSlider(value: 0.5, minValue: 0, maxValue: 1, target: nil, action: nil)
    private let leavesSpeedLabel = NSTextField(labelWithString: "")

    private let colorWell = NSColorWell()
    private let brightnessSlider = NSSlider(value: 0.9, minValue: 0.15, maxValue: 1, target: nil, action: nil)
    private let brightnessLabel = NSTextField(labelWithString: "")

    private struct Preset {
        let name: String
        let color: NSColor
    }

    private static let presets: [Preset] = [
        Preset(name: "Warm White", color: NSColor(calibratedRed: 1.0, green: 0.86, blue: 0.62, alpha: 1)),
        Preset(name: "Gold", color: NSColor(calibratedRed: 1.0, green: 0.74, blue: 0.30, alpha: 1)),
        Preset(name: "Red", color: NSColor(calibratedRed: 1.0, green: 0.38, blue: 0.33, alpha: 1)),
        Preset(name: "Green", color: NSColor(calibratedRed: 0.36, green: 0.85, blue: 0.52, alpha: 1)),
        Preset(name: "Ice Blue", color: NSColor(calibratedRed: 0.50, green: 0.78, blue: 1.0, alpha: 1)),
        Preset(name: "Pink", color: NSColor(calibratedRed: 1.0, green: 0.56, blue: 0.76, alpha: 1)),
        Preset(name: "Purple", color: NSColor(calibratedRed: 0.72, green: 0.52, blue: 1.0, alpha: 1))
    ]

    override init() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 470),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        super.init()

        window.title = "Atmosphere"
        window.isReleasedWhenClosed = false
        window.appearance = NSAppearance(named: .darkAqua)
        window.tabbingMode = .disallowed
        window.delegate = self

        buildContent()
        refresh()
    }

    func show() {
        refresh()
        NSApp.activate(ignoringOtherApps: true)
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    // MARK: - Building

    private func buildContent() {
        let background = NSVisualEffectView()
        background.material = .hudWindow
        background.blendingMode = .behindWindow
        background.state = .active
        window.contentView = background

        let leavesHeader = sectionTitle("Autumn Leaves 🍁")
        let densityRow = sliderRow(
            title: "Density",
            slider: leavesDensitySlider,
            label: leavesDensityLabel,
            action: #selector(changeLeavesDensity)
        )
        let speedRow = sliderRow(
            title: "Speed",
            slider: leavesSpeedSlider,
            label: leavesSpeedLabel,
            action: #selector(changeLeavesSpeed)
        )
        let leavesNote = note("Turn on “Autumn Leaves” in the control panel to see these changes.")

        let lightsHeader = sectionTitle("Christmas Lights 🎄")
        let colorRow = colorRow()
        let brightnessRow = sliderRow(
            title: "Brightness",
            slider: brightnessSlider,
            label: brightnessLabel,
            action: #selector(changeBrightness)
        )
        let lightsNote = note("Turn on “Christmas Lights” in the control panel to see these changes.")

        let stack = NSStackView(views: [
            leavesHeader,
            densityRow,
            speedRow,
            leavesNote,
            separator(),
            lightsHeader,
            colorRow,
            brightnessRow,
            lightsNote
        ])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.setCustomSpacing(16, after: leavesNote)
        stack.setCustomSpacing(16, after: lightsNote)
        stack.translatesAutoresizingMaskIntoConstraints = false

        background.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: background.topAnchor, constant: 22),
            stack.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: 22),
            stack.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -22),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: background.bottomAnchor, constant: -22)
        ])
    }

    private func sectionTitle(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .white
        return label
    }

    private func note(_ text: String) -> NSTextField {
        let label = NSTextField(wrappingLabelWithString: text)
        label.font = .systemFont(ofSize: 10)
        label.textColor = NSColor.white.withAlphaComponent(0.45)
        label.alignment = .left
        return label
    }

    private func separator() -> NSBox {
        let box = NSBox()
        box.boxType = .separator
        return box
    }

    private func sliderRow(
        title: String,
        slider: NSSlider,
        label: NSTextField,
        action: Selector
    ) -> NSView {
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 12)
        titleLabel.textColor = NSColor.white.withAlphaComponent(0.8)

        slider.target = self
        slider.action = action
        slider.isContinuous = true
        slider.controlSize = .small
        slider.translatesAutoresizingMaskIntoConstraints = false

        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = NSColor.white.withAlphaComponent(0.65)
        label.alignment = .right

        let row = NSStackView(views: [titleLabel, slider, label])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 10
        row.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.widthAnchor.constraint(equalToConstant: 80),
            slider.widthAnchor.constraint(equalToConstant: 170),
            label.widthAnchor.constraint(equalToConstant: 52)
        ])

        return row
    }

    private func colorRow() -> NSView {
        let titleLabel = NSTextField(labelWithString: "Colour")
        titleLabel.font = .systemFont(ofSize: 12)
        titleLabel.textColor = NSColor.white.withAlphaComponent(0.8)

        colorWell.target = self
        colorWell.action = #selector(changeColor)
        colorWell.translatesAutoresizingMaskIntoConstraints = false

        let swatches = NSStackView()
        swatches.orientation = .horizontal
        swatches.spacing = 6
        swatches.alignment = .centerY

        for (index, preset) in Self.presets.enumerated() {
            let button = NSButton(title: "", target: self, action: #selector(pickPreset(_:)))
            button.tag = index
            button.image = Self.swatchImage(color: preset.color)
            button.imagePosition = .imageOnly
            button.imageScaling = .scaleProportionallyDown
            button.isBordered = false
            button.bezelStyle = .regularSquare
            button.toolTip = preset.name
            button.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: 22),
                button.heightAnchor.constraint(equalToConstant: 22)
            ])
            swatches.addArrangedSubview(button)
        }

        let row = NSStackView(views: [titleLabel, colorWell, swatches])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 10
        row.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.widthAnchor.constraint(equalToConstant: 80),
            colorWell.widthAnchor.constraint(equalToConstant: 54),
            colorWell.heightAnchor.constraint(equalToConstant: 22)
        ])

        return row
    }

    private static func swatchImage(color: NSColor, size: CGFloat = 22) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()

        let rect = NSRect(x: 0.5, y: 0.5, width: size - 1, height: size - 1)
        let path = NSBezierPath(roundedRect: rect, xRadius: 6, yRadius: 6)
        color.setFill()
        path.fill()
        NSColor.white.withAlphaComponent(0.35).setStroke()
        path.lineWidth = 1
        path.stroke()

        image.unlockFocus()
        return image
    }

    // MARK: - Values

    private func refresh() {
        leavesDensitySlider.doubleValue = Settings.leavesDensity
        leavesSpeedSlider.doubleValue = Settings.leavesSpeed
        brightnessSlider.doubleValue = Settings.lightsBrightness
        colorWell.color = Settings.lightsColor

        updateLabels()
    }

    private func updateLabels() {
        leavesDensityLabel.stringValue = describe(leavesDensitySlider.doubleValue, low: "Few", high: "Lots")
        leavesSpeedLabel.stringValue = describe(leavesSpeedSlider.doubleValue, low: "Slow", high: "Wild")
        brightnessLabel.stringValue = "\(Int((brightnessSlider.doubleValue * 100).rounded()))%"
    }

    private func describe(_ value: Double, low: String, high: String) -> String {
        if value < 0.34 { return low }
        if value > 0.66 { return high }
        return "Medium"
    }

    // MARK: - Actions

    @objc private func changeLeavesDensity() {
        Settings.setLeavesDensity(leavesDensitySlider.doubleValue)
        updateLabels()
        SnowController.shared.applyAtmosphere()
    }

    @objc private func changeLeavesSpeed() {
        Settings.setLeavesSpeed(leavesSpeedSlider.doubleValue)
        updateLabels()
        SnowController.shared.applyAtmosphere()
    }

    @objc private func changeBrightness() {
        Settings.setLightsBrightness(brightnessSlider.doubleValue)
        updateLabels()
        SnowController.shared.applyAtmosphere()
    }

    @objc private func changeColor() {
        Settings.setLightsColor(colorWell.color)
        SnowController.shared.applyAtmosphere()
    }

    @objc private func pickPreset(_ sender: NSButton) {
        guard Self.presets.indices.contains(sender.tag) else { return }
        let preset = Self.presets[sender.tag]
        colorWell.color = preset.color
        changeColor()
    }
}
