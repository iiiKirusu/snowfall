import AppKit

/// A small credits window with links to the author's Instagram and GitHub.
/// The handles can be edited right here and are remembered between launches.
final class CreditsController: NSObject, NSWindowDelegate {
    private let window: NSWindow

    private let iconView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "Snowfall")
    private let versionLabel = NSTextField(labelWithString: "")
    private let authorField = NSTextField()
    private let instagramField = NSTextField()
    private let githubField = NSTextField()

    override init() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        super.init()

        window.title = "Credits"
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

        iconView.image = NSApp.applicationIconImage
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        titleLabel.textColor = .white

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        versionLabel.stringValue = "Version \(version) · macOS only for now"
        versionLabel.font = .systemFont(ofSize: 11)
        versionLabel.textColor = NSColor.white.withAlphaComponent(0.5)

        let madeBy = NSTextField(labelWithString: "Made by")
        madeBy.font = .systemFont(ofSize: 12)
        madeBy.textColor = NSColor.white.withAlphaComponent(0.6)

        authorField.font = .systemFont(ofSize: 13, weight: .medium)
        authorField.textColor = .white
        authorField.isBezeled = false
        authorField.drawsBackground = false
        authorField.alignment = .center
        authorField.target = self
        authorField.action = #selector(saveAuthor)

        let instagramRow = linkRow(
            title: "Instagram",
            placeholder: "your instagram handle",
            field: instagramField,
            buttonTitle: "Open",
            action: #selector(openInstagram)
        )

        let githubRow = linkRow(
            title: "GitHub",
            placeholder: "your github username",
            field: githubField,
            buttonTitle: "Open",
            action: #selector(openGitHub)
        )

        let hint = NSTextField(wrappingLabelWithString: "Edit the handles here any time — they are saved automatically.")
        hint.font = .systemFont(ofSize: 10)
        hint.textColor = NSColor.white.withAlphaComponent(0.4)
        hint.alignment = .center

        let separatorBox = separator()

        let stack = NSStackView(views: [
            iconView,
            titleLabel,
            versionLabel,
            madeBy,
            authorField,
            separatorBox,
            instagramRow,
            githubRow,
            hint
        ])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 8
        stack.setCustomSpacing(16, after: versionLabel)
        stack.setCustomSpacing(14, after: authorField)
        stack.setCustomSpacing(14, after: separatorBox)
        stack.setCustomSpacing(14, after: hint)
        stack.translatesAutoresizingMaskIntoConstraints = false

        background.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: background.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: background.centerYAnchor, constant: 2),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: background.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: background.trailingAnchor, constant: -24),

            iconView.widthAnchor.constraint(equalToConstant: 84),
            iconView.heightAnchor.constraint(equalToConstant: 84),
            authorField.widthAnchor.constraint(equalToConstant: 220)
        ])
    }

    private func separator() -> NSBox {
        let box = NSBox()
        box.boxType = .separator
        box.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            box.widthAnchor.constraint(equalToConstant: 260)
        ])
        return box
    }

    private func linkRow(
        title: String,
        placeholder: String,
        field: NSTextField,
        buttonTitle: String,
        action: Selector
    ) -> NSView {
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .white

        field.placeholderString = placeholder
        field.font = .systemFont(ofSize: 12)
        field.bezelStyle = .roundedBezel
        field.target = self
        field.action = #selector(saveHandles)

        let button = NSButton(title: buttonTitle, target: self, action: action)
        button.bezelStyle = .rounded
        button.font = .systemFont(ofSize: 12, weight: .medium)

        let row = NSStackView(views: [titleLabel, field, button])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 8

        NSLayoutConstraint.activate([
            titleLabel.widthAnchor.constraint(equalToConstant: 76),
            field.widthAnchor.constraint(equalToConstant: 160),
            button.widthAnchor.constraint(equalToConstant: 64)
        ])

        return row
    }

    // MARK: - Values

    private func refresh() {
        authorField.stringValue = Settings.authorName
        instagramField.stringValue = Settings.instagramHandle
        githubField.stringValue = Settings.githubHandle
    }

    @objc private func saveAuthor() {
        let trimmed = authorField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        Settings.setAuthorName(trimmed.isEmpty ? "kous" : trimmed)
    }

    @objc private func saveHandles() {
        Settings.setInstagramHandle(instagramField.stringValue)
        Settings.setGithubHandle(githubField.stringValue)
    }

    // MARK: - Actions

    @objc private func openInstagram() {
        saveHandles()
        open(handle: Settings.instagramHandle, url: "https://instagram.com/", name: "Instagram")
    }

    @objc private func openGitHub() {
        saveHandles()
        open(handle: Settings.githubHandle, url: "https://github.com/", name: "GitHub")
    }

    private func open(handle: String, url: String, name: String) {
        let clean = handle
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
            .replacingOccurrences(of: " ", with: "")

        guard !clean.isEmpty, let link = URL(string: url + clean) else {
            let alert = NSAlert()
            alert.messageText = "Add your \(name) handle first"
            alert.informativeText = "Type your \(name) handle in the box, then press Open."
            alert.addButton(withTitle: "OK")
            alert.beginSheetModal(for: window, completionHandler: nil)
            return
        }

        NSWorkspace.shared.open(link)
    }
}
