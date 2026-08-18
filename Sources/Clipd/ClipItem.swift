import Foundation

struct ClipItem: Codable, Identifiable, Equatable {
    let id: UUID
    var text: String
    var createdAt: Date
    var isPinned: Bool

    init(id: UUID = UUID(), text: String, createdAt: Date = Date(), isPinned: Bool = false) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.isPinned = isPinned
    }
}
