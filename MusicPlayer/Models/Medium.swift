import Foundation

// MARK: - Core Domain Model (iOS/macOS portable)

struct Medium: Identifiable, Hashable {
    let id: Int64
    var releaseId: Int64
    var position: Int  // 1-based: disc number / side order
    var format: String?  // optional override; e.g. "Vinyl Side A"
    var title: String?
    var createdAt: Date
    var updatedAt: Date
    
    // Transient properties (not persisted, loaded via relationships)
    var tracks: [Track]
    var release: Release?
    
    init(
        id: Int64,
        releaseId: Int64,
        position: Int = 1,
        format: String? = nil,
        title: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        tracks: [Track] = [],
        release: Release? = nil
    ) {
        self.id = id
        self.releaseId = releaseId
        self.position = position
        self.format = format
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.tracks = tracks
        self.release = release
    }
    
    enum CodingKeys: String, CodingKey {
        case id, releaseId, position, format, title, createdAt, updatedAt
    }
}
