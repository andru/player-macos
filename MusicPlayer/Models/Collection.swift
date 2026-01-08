import Foundation

// MARK: - Core Domain Model (iOS/macOS portable)

struct Collection: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var trackIDs: [Int64]

    init(id: UUID = UUID(), name: String, trackIDs: [Int64] = []) {
        self.id = id
        self.name = name
        self.trackIDs = trackIDs
    }
}
