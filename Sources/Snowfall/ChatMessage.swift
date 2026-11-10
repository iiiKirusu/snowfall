import Foundation

struct ChatMessage: Codable, Identifiable, Equatable {
    let id: String
    let senderID: String
    let senderName: String
    let text: String
    let timestamp: Date
}

enum ChatStatus: String {
    case offline
    case connecting
    case connected
}
