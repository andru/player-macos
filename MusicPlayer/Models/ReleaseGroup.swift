import Foundation

// MARK: - Core Domain Model (iOS/macOS portable)

/// Represents the album concept that users recognize
struct ReleaseGroup: Identifiable, Hashable {
    let id: Int64
    var title: String
    var primaryArtistId: Int64?  // nullable for compilations
    var isCompilation: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // Transient properties (not persisted, loaded via relationships)
    var releases: [Release]
    var primaryArtist: Artist?
    
    init(
        id: Int64,
        title: String,
        primaryArtistId: Int64? = nil,
        isCompilation: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        releases: [Release] = [],
        primaryArtist: Artist? = nil
    ) {
        self.id = id
        self.title = title
        self.primaryArtistId = primaryArtistId
        self.isCompilation = isCompilation
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.releases = releases
        self.primaryArtist = primaryArtist
    }
    
    var trackCount: Int {
        releases.reduce(0) { $0 + $1.trackCount }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, primaryArtistId, isCompilation, createdAt, updatedAt
    }
}
