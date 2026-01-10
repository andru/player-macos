import Foundation

// MARK: - Core Domain Model (iOS/macOS portable)

struct Work: Identifiable, Hashable {
    let id: Int64
    var title: String
    var createdAt: Date
    var updatedAt: Date
    
    // Transient properties (not persisted, loaded via relationships)
    var artists: [Artist]
    var recordings: [Recording]
    
    init(
        id: Int64,
        title: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        artists: [Artist] = [],
        recordings: [Recording] = []
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.artists = artists
        self.recordings = recordings
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, createdAt, updatedAt
    }
}
