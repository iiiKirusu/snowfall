import AppKit
import QuartzCore

/// A flipped document view so message rows stack from the top down.
private final class FlippedView: NSView {
    override var isFlipped: Bool { true }
}

/// The chat UI, built with plain AppKit so it works with the Command Line Tools
/// toolchain (the SwiftUI macro plugin is not available there).
final class ChatViewController: NSViewController, NSTextFieldDelegate {
    private let chat: ChatService

    private enum Colors {
        static let background = NSColor(calibratedRed: 0.045, green: 0.075, blue: 0.17, alpha: 1)
        static let snowflake = NSColor(calibratedRed: 0.72, green: 0.86, blue: 1.0, alpha: 1)
        static let bubbleStart = NSColor(calibratedRed: 0.30, green: 0.51, blue: 0.96, alpha: 1)
        static let bubbleEnd = NSColor(calibratedRed: 0.46, green: 0.34, blue: 0.92, alpha: 1)
        static let connected = NSColor(calibratedRed: 0.45, green: 0.90, blue: 0.60, alpha: 1)
        static let connecting = NSColor(calibratedRed: 1.00, green: 0.82, blue: 0.45, alpha: 1)
        static let offline = NSColor.white.withAlphaComponent(0.3)
    }

    // Header
    private let headerView = NSView()
    private let backButton = NSButton()
    private let iconView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "Snowfall Chat")
    private let statusDot = NSView()
    private let statusLabel = NSTextField(labelWithString: "")
    private let menuButton = NSButton()
    private let headerSeparator = NSBox()

    // Onboarding
    private let onboardingView = NSView()
    private let nameField = NSTextField()
    private let createButton = NSButton()
    private let inviteBox = NSView()
    private let inviteLabel = NSTextField(wrappingLabelWithString: "")
    private let copyInviteButton = NSButton()
    private let joinField = NSTextField()
    private let joinButton = NSButton()
    private let errorLabel = NSTextField(wrappingLabelWithString: "")
    private let onboardingSeparator = NSBox()

    // Conversation
    private let conversationView = NSView()
    private let scrollView = NSScrollView()
    private let messagesView = FlippedView()
    private let inputBar = NSView()
    private let inputField = NSTextField()
    private let sendButton = NSButton()

    private var lastSignature = ""
    private var lastWidth: CGFloat = 0

    /// Called when the back button is pressed.
    var onBack: (() -> Void)?

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    init(chat: ChatService) {
        self.chat = chat
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func loadView() {
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 420, height: 620))
        root.wantsLayer = true
        root.layer?.backgroundColor = Colors.background.cgColor
        view = root
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildHeader()
        buildOnboarding()
        buildConversation()
        layoutRoot()
        refresh()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(chatChanged),
            name: .snowfallChatChanged,
            object: nil
        )
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        if chat.isPaired {
            view.window?.makeFirstResponder(inputField)
        }
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        guard chat.isPaired else { return }
        let width = currentContentWidth()
        if abs(width - lastWidth) > 0.5 {
            rebuildMessages(width: width)
        }
    }

    // MARK: - Building the view

    private func buildHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false

        backButton.image = NSImage(systemSymbolName: "chevron.left", accessibilityDescription: "Back to Snowfall Controls")
        backButton.isBordered = false
        backButton.bezelStyle = .regularSquare
        backButton.imagePosition = .imageOnly
        backButton.contentTintColor = NSColor.white.withAlphaComponent(0.7)
        backButton.toolTip = "Back to Snowfall Controls"
        backButton.target = self
        backButton.action = #selector(goBack)
        backButton.translatesAutoresizingMaskIntoConstraints = false

        iconView.image = NSImage(systemSymbolName: "snowflake", accessibilityDescription: nil)
        iconView.contentTintColor = Colors.snowflake
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        statusDot.wantsLayer = true
        statusDot.layer?.cornerRadius = 3
        statusDot.translatesAutoresizingMaskIntoConstraints = false

        statusLabel.font = .systemFont(ofSize: 10)
        statusLabel.textColor = NSColor.white.withAlphaComponent(0.55)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        menuButton.image = NSImage(systemSymbolName: "ellipsis.circle", accessibilityDescription: "Chat options")
        menuButton.isBordered = false
        menuButton.bezelStyle = .regularSquare
        menuButton.imagePosition = .imageOnly
        menuButton.contentTintColor = NSColor.white.withAlphaComponent(0.7)
        menuButton.target = self
        menuButton.action = #selector(showMenu)
        menuButton.translatesAutoresizingMaskIntoConstraints = false

        headerSeparator.boxType = .separator
        headerSeparator.translatesAutoresizingMaskIntoConstraints = false

        headerView.addSubview(backButton)
        headerView.addSubview(iconView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(statusDot)
        headerView.addSubview(statusLabel)
        headerView.addSubview(menuButton)

        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 12),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 24),
            backButton.heightAnchor.constraint(equalToConstant: 24),

            iconView.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 8),
            iconView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 12),

            statusDot.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor, constant: 1),
            statusDot.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 7),
            statusDot.widthAnchor.constraint(equalToConstant: 6),
            statusDot.heightAnchor.constraint(equalToConstant: 6),

            statusLabel.leadingAnchor.constraint(equalTo: statusDot.trailingAnchor, constant: 5),
            statusLabel.centerYAnchor.constraint(equalTo: statusDot.centerYAnchor),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: menuButton.leadingAnchor, constant: -10),

            menuButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            menuButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            menuButton.widthAnchor.constraint(equalToConstant: 28),
            menuButton.heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    private func buildOnboarding() {
        onboardingView.translatesAutoresizingMaskIntoConstraints = false

        let heading = NSTextField(wrappingLabelWithString: "A private line just for you two.")
        heading.font = .systemFont(ofSize: 19, weight: .semibold)
        heading.textColor = .white

        let blurb = NSTextField(wrappingLabelWithString: "Share an invite code with your girlfriend. Messages are end-to-end encrypted — the relay only sees scrambled data, and only your two Macs can read it.")
        blurb.font = .systemFont(ofSize: 12)
        blurb.textColor = NSColor.white.withAlphaComponent(0.6)

        let nameTitle = NSTextField(labelWithString: "Your name")
        nameTitle.font = .systemFont(ofSize: 11, weight: .medium)
        nameTitle.textColor = NSColor.white.withAlphaComponent(0.5)

        nameField.placeholderString = "Your name"
        nameField.font = .systemFont(ofSize: 13)
        nameField.bezelStyle = .roundedBezel
        nameField.delegate = self

        createButton.title = "Create Our Invite Code"
        createButton.bezelStyle = .rounded
        createButton.bezelColor = Colors.bubbleStart
        createButton.contentTintColor = .white
        createButton.font = .systemFont(ofSize: 13, weight: .semibold)
        createButton.controlSize = .large
        createButton.target = self
        createButton.action = #selector(createInvite)

        buildInviteBox()

        onboardingSeparator.boxType = .separator

        let joinTitle = NSTextField(labelWithString: "Have a code from her?")
        joinTitle.font = .systemFont(ofSize: 13, weight: .semibold)
        joinTitle.textColor = .white

        joinField.placeholderString = "Paste invite code"
        joinField.font = .systemFont(ofSize: 12)
        joinField.bezelStyle = .roundedBezel
        joinField.target = self
        joinField.action = #selector(join)
        joinField.setContentHuggingPriority(.defaultLow, for: .horizontal)

        joinButton.title = "Join"
        joinButton.bezelStyle = .rounded
        joinButton.target = self
        joinButton.action = #selector(join)
        joinButton.setContentHuggingPriority(.required, for: .horizontal)

        let joinRow = NSStackView(views: [joinField, joinButton])
        joinRow.orientation = .horizontal
        joinRow.spacing = 8

        errorLabel.font = .systemFont(ofSize: 11)
        errorLabel.textColor = NSColor(calibratedRed: 1.0, green: 0.5, blue: 0.5, alpha: 1)
        errorLabel.isHidden = true

        let note = NSTextField(wrappingLabelWithString: "Invite codes work like a password. Keep yours between the two of you.")
        note.font = .systemFont(ofSize: 10)
        note.textColor = NSColor.white.withAlphaComponent(0.35)

        for label in [heading, blurb, nameTitle, joinTitle, note] {
            label.alignment = .left
        }

        let stack = NSStackView(views: [
            heading,
            blurb,
            nameTitle,
            nameField,
            createButton,
            inviteBox,
            onboardingSeparator,
            joinTitle,
            joinRow,
            errorLabel,
            note
        ])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.setCustomSpacing(6, after: nameTitle)
        stack.setCustomSpacing(10, after: createButton)
        stack.setCustomSpacing(18, after: inviteBox)
        stack.setCustomSpacing(8, after: joinTitle)
        stack.translatesAutoresizingMaskIntoConstraints = false

        onboardingView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: onboardingView.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: onboardingView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: onboardingView.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: onboardingView.bottomAnchor, constant: -20),
            nameField.heightAnchor.constraint(equalToConstant: 26),
            createButton.heightAnchor.constraint(equalToConstant: 34),
            joinField.heightAnchor.constraint(equalToConstant: 26)
        ])

        // Make the full-width controls stretch, while labels keep their natural width.
        for view in [blurb, nameField, createButton, inviteBox, onboardingSeparator, joinRow, errorLabel, note] {
            view.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        }
    }

    private func buildInviteBox() {
        inviteBox.wantsLayer = true
        inviteBox.layer?.cornerRadius = 10
        inviteBox.layer?.backgroundColor = Colors.snowflake.withAlphaComponent(0.08).cgColor
        inviteBox.isHidden = true
        inviteBox.translatesAutoresizingMaskIntoConstraints = false

        let inviteTitle = NSTextField(labelWithString: "YOUR INVITE CODE")
        inviteTitle.font = .systemFont(ofSize: 10, weight: .medium)
        inviteTitle.textColor = NSColor.white.withAlphaComponent(0.5)

        inviteLabel.font = .monospacedSystemFont(ofSize: 12, weight: .medium)
        inviteLabel.textColor = NSColor(calibratedRed: 0.82, green: 0.9, blue: 1.0, alpha: 1)
        inviteLabel.isSelectable = true

        copyInviteButton.title = "Copy Code"
        copyInviteButton.isBordered = false
        copyInviteButton.font = .systemFont(ofSize: 11, weight: .medium)
        copyInviteButton.contentTintColor = Colors.snowflake
        copyInviteButton.target = self
        copyInviteButton.action = #selector(copyInvite)

        let hint = NSTextField(wrappingLabelWithString: "Send it to her with iMessage, then paste it in her Snowfall.")
        hint.font = .systemFont(ofSize: 10)
        hint.textColor = NSColor.white.withAlphaComponent(0.45)

        let stack = NSStackView(views: [inviteTitle, inviteLabel, copyInviteButton, hint])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false

        inviteBox.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: inviteBox.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: inviteBox.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: inviteBox.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: inviteBox.bottomAnchor, constant: -12)
        ])
    }

    private func buildConversation() {
        conversationView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.documentView = messagesView
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        let inputSeparator = NSBox()
        inputSeparator.boxType = .separator
        inputSeparator.translatesAutoresizingMaskIntoConstraints = false

        inputBar.translatesAutoresizingMaskIntoConstraints = false

        inputField.placeholderString = "Message…"
        inputField.font = .systemFont(ofSize: 13)
        inputField.bezelStyle = .roundedBezel
        inputField.target = self
        inputField.action = #selector(sendMessage)
        inputField.translatesAutoresizingMaskIntoConstraints = false

        sendButton.image = NSImage(systemSymbolName: "arrow.up.circle.fill", accessibilityDescription: "Send")
        sendButton.isBordered = false
        sendButton.bezelStyle = .regularSquare
        sendButton.imagePosition = .imageOnly
        sendButton.contentTintColor = NSColor(calibratedRed: 0.55, green: 0.76, blue: 1.0, alpha: 1)
        sendButton.target = self
        sendButton.action = #selector(sendMessage)
        sendButton.translatesAutoresizingMaskIntoConstraints = false

        inputBar.addSubview(inputSeparator)
        inputBar.addSubview(inputField)
        inputBar.addSubview(sendButton)

        conversationView.addSubview(scrollView)
        conversationView.addSubview(inputBar)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: conversationView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: conversationView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: conversationView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: inputBar.topAnchor),

            inputBar.leadingAnchor.constraint(equalTo: conversationView.leadingAnchor),
            inputBar.trailingAnchor.constraint(equalTo: conversationView.trailingAnchor),
            inputBar.bottomAnchor.constraint(equalTo: conversationView.bottomAnchor),
            inputBar.heightAnchor.constraint(equalToConstant: 58),

            inputSeparator.topAnchor.constraint(equalTo: inputBar.topAnchor),
            inputSeparator.leadingAnchor.constraint(equalTo: inputBar.leadingAnchor),
            inputSeparator.trailingAnchor.constraint(equalTo: inputBar.trailingAnchor),
            inputSeparator.heightAnchor.constraint(equalToConstant: 1),

            inputField.leadingAnchor.constraint(equalTo: inputBar.leadingAnchor, constant: 14),
            inputField.centerYAnchor.constraint(equalTo: inputBar.centerYAnchor, constant: 1),
            inputField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -10),
            inputField.heightAnchor.constraint(equalToConstant: 28),

            sendButton.trailingAnchor.constraint(equalTo: inputBar.trailingAnchor, constant: -14),
            sendButton.centerYAnchor.constraint(equalTo: inputBar.centerYAnchor, constant: 1),
            sendButton.widthAnchor.constraint(equalToConstant: 30),
            sendButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    private func layoutRoot() {
        view.addSubview(headerView)
        view.addSubview(headerSeparator)
        view.addSubview(onboardingView)
        view.addSubview(conversationView)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 60),

            headerSeparator.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            headerSeparator.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerSeparator.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerSeparator.heightAnchor.constraint(equalToConstant: 1),

            onboardingView.topAnchor.constraint(equalTo: headerSeparator.bottomAnchor),
            onboardingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            onboardingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            onboardingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            conversationView.topAnchor.constraint(equalTo: headerSeparator.bottomAnchor),
            conversationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            conversationView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            conversationView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Refresh

    @objc private func chatChanged() {
        if Thread.isMainThread {
            refresh()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.refresh()
            }
        }
    }

    private func refresh() {
        statusLabel.stringValue = statusText
        statusDot.layer?.backgroundColor = statusColor.cgColor

        let paired = chat.isPaired
        onboardingView.isHidden = paired
        conversationView.isHidden = !paired
        menuButton.isHidden = !paired

        nameField.stringValue = chat.myName
        errorLabel.stringValue = chat.lastError ?? ""
        errorLabel.isHidden = (chat.lastError ?? "").isEmpty

        if let invite = chat.inviteCode {
            inviteBox.isHidden = false
            inviteLabel.stringValue = invite
        } else {
            inviteBox.isHidden = true
            inviteLabel.stringValue = ""
        }

        guard paired else {
            lastSignature = ""
            return
        }

        let signature = signatureForMessages()
        let width = currentContentWidth()
        if signature != lastSignature || abs(width - lastWidth) > 0.5 {
            rebuildMessages(width: width)
        }
    }

    private func signatureForMessages() -> String {
        chat.messages.map { $0.id }.joined(separator: "|") + "#\(chat.messages.count)"
    }

    private func currentContentWidth() -> CGFloat {
        let clipWidth = scrollView.contentView.bounds.width
        if clipWidth > 1 {
            return clipWidth
        }
        return max(view.bounds.width, 320)
    }

    private var statusText: String {
        switch chat.status {
        case .connected:
            return chat.isPaired ? "Connected · end-to-end encrypted" : "Connected"
        case .connecting:
            return "Connecting…"
        case .offline:
            return chat.isPaired ? "Offline — retrying" : "Not paired yet"
        }
    }

    private var statusColor: NSColor {
        switch chat.status {
        case .connected: return Colors.connected
        case .connecting: return Colors.connecting
        case .offline: return Colors.offline
        }
    }

    // MARK: - Messages

    private func rebuildMessages(width: CGFloat) {
        lastSignature = signatureForMessages()
        lastWidth = width

        messagesView.subviews.forEach { $0.removeFromSuperview() }

        let contentWidth = max(width, 240)
        var y: CGFloat = 14

        if chat.messages.isEmpty, let invite = chat.inviteCode {
            let cardWidth = min(360, contentWidth - 40)
            let card = makeInviteCard(invite: invite, width: cardWidth)
            card.frame.origin = NSPoint(x: (contentWidth - cardWidth) / 2, y: 60)
            messagesView.addSubview(card)
            y = 60 + card.frame.height + 20
        } else if chat.messages.isEmpty {
            let empty = NSTextField(labelWithString: "Say hi to your person ❄️")
            empty.font = .systemFont(ofSize: 13)
            empty.textColor = NSColor.white.withAlphaComponent(0.5)
            empty.alignment = .center
            empty.frame = NSRect(x: 0, y: 80, width: contentWidth, height: 20)
            messagesView.addSubview(empty)
            y = 120
        } else {
            for message in chat.messages {
                let isMine = message.senderID == chat.myID
                let font = NSFont.systemFont(ofSize: 13)
                let maxTextWidth = min(300, contentWidth * 0.72)

                // Measure with the actual label cell so the bubble is wide enough
                // for the text instead of clipping its tail.
                let probe = NSTextField(wrappingLabelWithString: message.text)
                probe.font = font
                let measured = probe.cell?.cellSize(
                    forBounds: NSRect(x: 0, y: 0, width: maxTextWidth, height: CGFloat.greatestFiniteMagnitude)
                ) ?? NSSize(width: maxTextWidth, height: 16)
                let textWidth = min(max(ceil(measured.width), 1), maxTextWidth)
                let textHeight = max(ceil(measured.height), 16)
                let bubbleWidth = textWidth + 24
                let bubbleHeight = textHeight + 16

                let x: CGFloat = isMine ? contentWidth - 16 - bubbleWidth : 16

                if !isMine {
                    let name = NSTextField(labelWithString: message.senderName)
                    name.font = .systemFont(ofSize: 10, weight: .medium)
                    name.textColor = NSColor.white.withAlphaComponent(0.45)
                    name.lineBreakMode = .byTruncatingTail
                    name.frame = NSRect(x: x + 4, y: y, width: bubbleWidth, height: 13)
                    messagesView.addSubview(name)
                    y += 15
                }

                let bubble = makeBubble(
                    text: message.text,
                    isMine: isMine,
                    width: bubbleWidth,
                    height: bubbleHeight,
                    textWidth: textWidth,
                    textHeight: textHeight
                )
                bubble.frame.origin = NSPoint(x: x, y: y)
                messagesView.addSubview(bubble)
                y += bubbleHeight + 3

                let time = NSTextField(labelWithString: Self.timeFormatter.string(from: message.timestamp))
                time.font = .systemFont(ofSize: 9)
                time.textColor = NSColor.white.withAlphaComponent(0.3)
                time.alignment = isMine ? .right : .left
                time.frame = NSRect(x: isMine ? x : x, y: y, width: bubbleWidth, height: 11)
                messagesView.addSubview(time)
                y += 11 + 12
            }
        }

        let clipHeight = scrollView.contentView.bounds.height
        let contentHeight = max(y + 6, clipHeight)
        messagesView.frame = NSRect(x: 0, y: 0, width: contentWidth, height: contentHeight)
        messagesView.layoutSubtreeIfNeeded()
        scrollToBottom()
    }

    private func makeInviteCard(invite: String, width: CGFloat) -> NSView {
        let padding: CGFloat = 14
        let innerWidth = width - padding * 2

        let titleText = "Share this invite code with your person so she can join:"
        let titleFont = NSFont.systemFont(ofSize: 12)
        let titleHeight = textHeight(titleText, font: titleFont, width: innerWidth)

        let codeLabel = NSTextField(labelWithString: invite)
        codeLabel.font = .monospacedSystemFont(ofSize: 12, weight: .medium)
        codeLabel.textColor = NSColor(calibratedRed: 0.82, green: 0.9, blue: 1.0, alpha: 1)
        codeLabel.isSelectable = true
        codeLabel.lineBreakMode = .byClipping
        let codeHeight: CGFloat = 16

        let copy = NSButton(title: "Copy Code", target: self, action: #selector(copyInvite))
        copy.isBordered = false
        copy.font = .systemFont(ofSize: 11, weight: .medium)
        copy.contentTintColor = Colors.snowflake
        let copyHeight: CGFloat = 18

        let hintText = "Then say hi below ❄️"
        let hintFont = NSFont.systemFont(ofSize: 10)
        let hintHeight = textHeight(hintText, font: hintFont, width: innerWidth)

        let totalHeight = padding * 2 + titleHeight + 8 + codeHeight + 6 + copyHeight + 8 + hintHeight
        let card = FlippedView(frame: NSRect(x: 0, y: 0, width: width, height: totalHeight))
        card.wantsLayer = true
        card.layer?.cornerRadius = 12
        card.layer?.backgroundColor = Colors.snowflake.withAlphaComponent(0.08).cgColor

        var y = padding
        let title = NSTextField(wrappingLabelWithString: titleText)
        title.font = titleFont
        title.textColor = NSColor.white.withAlphaComponent(0.65)
        title.alignment = .left
        title.frame = NSRect(x: padding, y: y, width: innerWidth, height: titleHeight)
        card.addSubview(title)
        y += titleHeight + 8

        codeLabel.frame = NSRect(x: padding, y: y, width: innerWidth, height: codeHeight)
        card.addSubview(codeLabel)
        y += codeHeight + 6

        copy.frame = NSRect(x: padding - 4, y: y, width: 90, height: copyHeight)
        card.addSubview(copy)
        y += copyHeight + 8

        let hint = NSTextField(wrappingLabelWithString: hintText)
        hint.font = hintFont
        hint.textColor = NSColor.white.withAlphaComponent(0.45)
        hint.alignment = .left
        hint.frame = NSRect(x: padding, y: y, width: innerWidth, height: hintHeight)
        card.addSubview(hint)

        return card
    }

    private func textHeight(_ text: String, font: NSFont, width: CGFloat) -> CGFloat {
        let probe = NSTextField(wrappingLabelWithString: text)
        probe.font = font
        let size = probe.cell?.cellSize(
            forBounds: NSRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude)
        ) ?? NSSize(width: width, height: 16)
        return max(ceil(size.height), 14)
    }

    private func makeBubble(
        text: String,
        isMine: Bool,
        width: CGFloat,
        height: CGFloat,
        textWidth: CGFloat,
        textHeight: CGFloat
    ) -> NSView {
        let bubble = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        bubble.wantsLayer = true
        bubble.layer?.cornerRadius = 14
        bubble.layer?.masksToBounds = true

        if isMine {
            let gradient = CAGradientLayer()
            gradient.frame = bubble.bounds
            gradient.cornerRadius = 14
            gradient.startPoint = CGPoint(x: 0, y: 0)
            gradient.endPoint = CGPoint(x: 1, y: 1)
            gradient.colors = [Colors.bubbleStart.cgColor, Colors.bubbleEnd.cgColor]
            bubble.layer?.insertSublayer(gradient, at: 0)
        } else {
            bubble.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.09).cgColor
        }

        let label = NSTextField(wrappingLabelWithString: text)
        label.font = .systemFont(ofSize: 13)
        label.textColor = NSColor.white.withAlphaComponent(isMine ? 1 : 0.92)
        label.isSelectable = true
        label.drawsBackground = false
        label.isBezeled = false
        label.frame = NSRect(x: 12, y: 8, width: textWidth, height: textHeight)
        bubble.addSubview(label)

        return bubble
    }

    private func scrollToBottom() {
        messagesView.layoutSubtreeIfNeeded()
        let clip = scrollView.contentView
        let targetY = max(0, messagesView.frame.height - clip.bounds.height)
        clip.scroll(to: NSPoint(x: 0, y: targetY))
        scrollView.reflectScrolledClipView(clip)
    }

    // MARK: - Actions

    @objc private func goBack() {
        onBack?()
    }

    @objc private func createInvite() {
        let trimmed = nameField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            chat.myName = String(trimmed.prefix(40))
        }
        chat.createInvite()
        refresh()
        view.window?.makeFirstResponder(inputField)
    }

    @objc private func join() {
        if chat.join(code: joinField.stringValue) {
            joinField.stringValue = ""
            refresh()
            view.window?.makeFirstResponder(inputField)
        } else {
            refresh()
        }
    }

    @objc private func sendMessage() {
        let text = inputField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        chat.send(text: text)
        inputField.stringValue = ""
        refresh()
        view.window?.makeFirstResponder(inputField)
    }

    @objc private func copyInvite() {
        guard let invite = chat.inviteCode else { return }
        copyToPasteboard(invite)
    }

    private func copyToPasteboard(_ string: String) {
        guard !string.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
    }

    @objc private func showMenu(_ sender: NSButton) {
        let menu = NSMenu()

        let copy = NSMenuItem(title: "Copy Invite Code", action: #selector(copyInvite), keyEquivalent: "")
        copy.target = self
        menu.addItem(copy)

        let rename = NSMenuItem(title: "Change My Name…", action: #selector(changeName), keyEquivalent: "")
        rename.target = self
        menu.addItem(rename)

        menu.addItem(.separator())

        let unpair = NSMenuItem(title: "Unpair", action: #selector(unpair), keyEquivalent: "")
        unpair.target = self
        menu.addItem(unpair)

        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height + 4), in: sender)
    }

    @objc private func changeName() {
        let alert = NSAlert()
        alert.messageText = "Your name"
        alert.informativeText = "This is what your girlfriend sees next to your messages."

        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        field.stringValue = chat.myName
        alert.accessoryView = field

        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")

        let finish: (NSApplication.ModalResponse) -> Void = { [weak self] response in
            guard let self, response == .alertFirstButtonReturn else { return }
            let trimmed = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                self.chat.myName = String(trimmed.prefix(40))
                self.refresh()
            }
        }

        if let window = view.window {
            alert.beginSheetModal(for: window, completionHandler: finish)
        } else {
            finish(alert.runModal())
        }
    }

    @objc private func unpair() {
        let alert = NSAlert()
        alert.messageText = "Unpair this chat?"
        alert.informativeText = "You’ll need the invite code again to reconnect. Messages stored on this Mac will be cleared."
        alert.addButton(withTitle: "Unpair")
        alert.addButton(withTitle: "Cancel")

        let finish: (NSApplication.ModalResponse) -> Void = { [weak self] response in
            guard let self, response == .alertFirstButtonReturn else { return }
            self.chat.unpair()
            self.refresh()
        }

        if let window = view.window {
            alert.beginSheetModal(for: window, completionHandler: finish)
        } else {
            finish(alert.runModal())
        }
    }

    // MARK: - NSTextFieldDelegate

    func controlTextDidEndEditing(_ obj: Notification) {
        guard let field = obj.object as? NSTextField, field === nameField else { return }
        let trimmed = nameField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            chat.myName = String(trimmed.prefix(40))
        }
    }
}
