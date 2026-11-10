import Foundation
import Combine
import CryptoKit
import Security

/// A private, end-to-end encrypted two-person chat.
///
/// Pairing is done with a 32-character invite code. That code derives both the
/// relay topic name and the encryption key, so the relay (ntfy.sh) only ever
/// sees encrypted blobs. The invite code is effectively the shared password.
final class ChatService: NSObject, ObservableObject {
    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var isPaired = false
    @Published private(set) var status: ChatStatus = .offline
    @Published private(set) var unreadCount = 0
    @Published private(set) var inviteCode: String?
    @Published private(set) var lastError: String?

    @Published var myName: String {
        didSet {
            defaults.set(myName, forKey: Key.name)
        }
    }

    let myID: String

    private enum Key {
        static let code = "chat.code"
        static let senderID = "chat.senderID"
        static let name = "chat.name"
        static let messages = "chat.messages"
        static let lastNtfyID = "chat.lastNtfyID"
        static let unread = "chat.unread"
    }

    private let defaults: UserDefaults
    private var code: String?
    private var lastNtfyID: String?
    private var socket: URLSessionWebSocketTask?
    private var session: URLSession!
    private var reconnectWorkItem: DispatchWorkItem?
    private var reconnectAttempt = 0
    private var isChatVisible = false
    private var isStarted = false

    private static let relayBase = "ntfy.sh"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let storedID = defaults.string(forKey: Key.senderID) {
            myID = storedID
        } else {
            let newID = UUID().uuidString
            myID = newID
            defaults.set(newID, forKey: Key.senderID)
        }

        let storedName = defaults.string(forKey: Key.name) ?? ""
        let fullName = NSFullUserName()
        myName = storedName.isEmpty
            ? (fullName.isEmpty ? "Me" : fullName)
            : storedName

        super.init()

        session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)

        code = defaults.string(forKey: Key.code)
        isPaired = code != nil
        inviteCode = code.map(Self.formatCode)
        messages = Self.loadMessages(from: defaults)
        lastNtfyID = defaults.string(forKey: Key.lastNtfyID)
        unreadCount = defaults.integer(forKey: Key.unread)
    }

    deinit {
        reconnectWorkItem?.cancel()
        socket?.cancel(with: .goingAway, reason: nil)
    }

    // MARK: - Public API

    func start() {
        guard !isStarted else { return }
        isStarted = true
        if isPaired {
            connect()
        }
    }

    func setChatVisible(_ visible: Bool) {
        isChatVisible = visible
        if visible {
            markRead()
        }
    }

    func markRead() {
        guard unreadCount != 0 else { return }
        unreadCount = 0
        defaults.set(0, forKey: Key.unread)
        postChanged()
    }

    func createInvite() {
        pair(with: Self.generateCode())
    }

    @discardableResult
    func join(code input: String) -> Bool {
        guard let normalized = Self.normalizeCode(input) else {
            lastError = "That invite code doesn’t look right. It should contain 32 letters and numbers."
            return false
        }
        pair(with: normalized)
        return true
    }

    func unpair() {
        disconnect()
        code = nil
        isPaired = false
        inviteCode = nil
        lastNtfyID = nil
        messages = []
        unreadCount = 0
        lastError = nil

        defaults.removeObject(forKey: Key.code)
        defaults.removeObject(forKey: Key.messages)
        defaults.removeObject(forKey: Key.lastNtfyID)
        defaults.removeObject(forKey: Key.unread)

        postChanged()
    }

    func send(text: String) {
        let trimmed = String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(2000))
        guard !trimmed.isEmpty, isPaired, let code else { return }

        let payload = ChatPayload(
            id: UUID().uuidString,
            senderID: myID,
            name: myName,
            text: trimmed,
            timestamp: Date().timeIntervalSince1970
        )

        let message = ChatMessage(
            id: payload.id,
            senderID: myID,
            senderName: myName,
            text: trimmed,
            timestamp: Date(timeIntervalSince1970: payload.timestamp)
        )
        ingest(message)

        guard let body = encrypt(payload, code: code) else { return }
        publish(body, code: code)
    }

    func reconnectNow() {
        guard isPaired else { return }
        reconnectAttempt = 0
        connect()
    }

    // MARK: - Pairing

    private func pair(with newCode: String) {
        disconnect()

        code = newCode
        isPaired = true
        inviteCode = Self.formatCode(newCode)
        messages = []
        unreadCount = 0
        lastNtfyID = nil
        lastError = nil
        reconnectAttempt = 0

        defaults.set(newCode, forKey: Key.code)
        defaults.removeObject(forKey: Key.messages)
        defaults.removeObject(forKey: Key.lastNtfyID)
        defaults.set(0, forKey: Key.unread)

        postChanged()
        connect()
    }

    private static func generateCode() -> String {
        var bytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    static func normalizeCode(_ input: String) -> String? {
        let hex = input.uppercased().filter { $0.isHexDigit }
        guard hex.count == 32 else { return nil }
        return String(hex).lowercased()
    }

    static func formatCode(_ code: String) -> String {
        let upper = code.uppercased()
        var groups: [String] = []
        var index = upper.startIndex

        while index < upper.endIndex {
            let end = upper.index(index, offsetBy: 4, limitedBy: upper.endIndex) ?? upper.endIndex
            groups.append(String(upper[index..<end]))
            index = end
        }

        return "SNOW-" + groups.joined(separator: "-")
    }

    // MARK: - Relay (ntfy.sh)

    private func connect() {
        guard let code, let url = webSocketURL(code: code) else { return }

        reconnectWorkItem?.cancel()
        socket?.cancel(with: .goingAway, reason: nil)

        status = .connecting
        postChanged()

        let task = session.webSocketTask(with: url)
        socket = task
        task.resume()
        receiveLoop(task)
    }

    private func disconnect() {
        reconnectWorkItem?.cancel()
        reconnectWorkItem = nil
        socket?.cancel(with: .goingAway, reason: nil)
        socket = nil
        status = .offline
    }

    private func webSocketURL(code: String) -> URL? {
        var components = URLComponents()
        components.scheme = "wss"
        components.host = Self.relayBase
        components.path = "/\(topic(for: code))/ws"
        components.queryItems = [URLQueryItem(name: "since", value: lastNtfyID ?? "12h")]
        return components.url
    }

    private func publish(_ body: String, code: String) {
        guard let url = URL(string: "https://\(Self.relayBase)/\(topic(for: code))") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/plain; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data(body.utf8)

        session.dataTask(with: request) { [weak self] _, response, error in
            guard let self else { return }
            if let error {
                DispatchQueue.main.async {
                    self.lastError = "Message not sent: \(error.localizedDescription)"
                }
            } else if let http = response as? HTTPURLResponse, http.statusCode >= 300 {
                DispatchQueue.main.async {
                    self.lastError = "Message not sent (server error \(http.statusCode))."
                }
            }
        }.resume()
    }

    private func receiveLoop(_ task: URLSessionWebSocketTask) {
        task.receive { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleRawEvent(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleRawEvent(text)
                    }
                @unknown default:
                    break
                }
                self.receiveLoop(task)

            case .failure:
                DispatchQueue.main.async {
                    guard self.socket === task else { return }
                    self.status = .offline
                    self.postChanged()
                    self.scheduleReconnect()
                }
            }
        }
    }

    private func handleRawEvent(_ text: String) {
        guard let data = text.data(using: .utf8),
              let event = try? JSONDecoder().decode(NtfyEvent.self, from: data),
              event.event == "message",
              let messageBody = event.message else {
            return
        }

        DispatchQueue.main.async {
            if let ntfyID = event.id {
                self.lastNtfyID = ntfyID
                self.defaults.set(ntfyID, forKey: Key.lastNtfyID)
            }

            guard let code = self.code,
                  let payload = self.decrypt(messageBody, code: code) else {
                return
            }

            let message = ChatMessage(
                id: payload.id,
                senderID: payload.senderID,
                senderName: payload.name,
                text: payload.text,
                timestamp: Date(timeIntervalSince1970: payload.timestamp)
            )
            self.ingest(message)
        }
    }

    private func scheduleReconnect() {
        guard isPaired else { return }

        reconnectWorkItem?.cancel()
        reconnectAttempt += 1
        let delay = min(pow(2.0, Double(reconnectAttempt)) * 2.0, 30.0)

        let work = DispatchWorkItem { [weak self] in
            self?.connect()
        }
        reconnectWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    // MARK: - Messages

    private func ingest(_ message: ChatMessage) {
        let isNew = !messages.contains { $0.id == message.id }

        if isNew {
            messages.append(message)
            messages.sort { $0.timestamp < $1.timestamp }
            if messages.count > 300 {
                messages.removeFirst(messages.count - 300)
            }
        }

        if isNew, !isChatVisible, message.senderID != myID {
            unreadCount += 1
            defaults.set(unreadCount, forKey: Key.unread)
        }

        if let data = try? JSONEncoder().encode(messages) {
            defaults.set(data, forKey: Key.messages)
        }

        postChanged()
    }

    private static func loadMessages(from defaults: UserDefaults) -> [ChatMessage] {
        guard let data = defaults.data(forKey: Key.messages),
              let stored = try? JSONDecoder().decode([ChatMessage].self, from: data) else {
            return []
        }
        return stored.sorted { $0.timestamp < $1.timestamp }
    }

    private func postChanged() {
        NotificationCenter.default.post(name: .snowfallChatChanged, object: nil)
    }

    // MARK: - Crypto

    private struct ChatPayload: Codable {
        let id: String
        let senderID: String
        let name: String
        let text: String
        let timestamp: Double
    }

    private struct NtfyEvent: Decodable {
        let id: String?
        let event: String?
        let message: String?
    }

    private func topic(for code: String) -> String {
        let digest = SHA256.hash(data: Data(("snowfall-topic|" + code).utf8))
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return "snowfall-" + hex.prefix(24)
    }

    private func symmetricKey(for code: String) -> SymmetricKey {
        let digest = SHA256.hash(data: Data(("snowfall-key|" + code).utf8))
        return SymmetricKey(data: digest)
    }

    private func encrypt(_ payload: ChatPayload, code: String) -> String? {
        guard let data = try? JSONEncoder().encode(payload),
              let sealed = try? AES.GCM.seal(data, using: symmetricKey(for: code)),
              let combined = sealed.combined else {
            return nil
        }
        return combined.base64EncodedString()
    }

    private func decrypt(_ body: String, code: String) -> ChatPayload? {
        guard let data = Data(base64Encoded: body),
              let box = try? AES.GCM.SealedBox(combined: data),
              let plain = try? AES.GCM.open(box, using: symmetricKey(for: code)),
              let payload = try? JSONDecoder().decode(ChatPayload.self, from: plain) else {
            return nil
        }
        return payload
    }
}

extension ChatService: URLSessionWebSocketDelegate {
    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        DispatchQueue.main.async {
            guard self.socket === webSocketTask else { return }
            self.status = .connected
            self.reconnectAttempt = 0
            self.lastError = nil
            self.postChanged()
        }
    }

    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        DispatchQueue.main.async {
            guard self.socket === webSocketTask else { return }
            self.status = .offline
            self.postChanged()
            self.scheduleReconnect()
        }
    }
}
