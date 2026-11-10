import AppKit

final class ChatWindowController: NSObject, NSWindowDelegate {
    private let chat: ChatService
    private let window: NSWindow
    private let chatViewController: ChatViewController

    init(chat: ChatService) {
        self.chat = chat
        chatViewController = ChatViewController(chat: chat)

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        super.init()

        window.title = "Snowfall Chat"
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 380, height: 540)
        window.appearance = NSAppearance(named: .darkAqua)
        window.backgroundColor = NSColor(calibratedRed: 0.045, green: 0.075, blue: 0.17, alpha: 1)
        window.isMovableByWindowBackground = true
        window.tabbingMode = .disallowed
        window.delegate = self
        window.contentViewController = chatViewController
        window.center()
    }

    func show() {
        chat.setChatVisible(true)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func windowDidBecomeKey(_ notification: Notification) {
        chat.markRead()
    }

    func windowWillClose(_ notification: Notification) {
        chat.setChatVisible(false)
    }
}
