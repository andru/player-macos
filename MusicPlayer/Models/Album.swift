import Foundation

// MARK: - Core Domain Model (iOS/macOS portable)

struct Album: Identifiable, Hashable {
    let id: Int64
    var artistId: Int64
    var artistName: String
    var title: String
    var sortTitle: String?
    var albumArtistName: String?
    var composerName: String?
    var isCompilation: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // Transient properties (not persisted, loaded via relationships)
    var releases: [Release]
    var artist: Artist?
    
    init(
        id: Int64,
        artistId: Int64,
        title: String,
        sortTitle: String? = nil,
        albumArtistName: String? = nil,
        composerName: String? = nil,
        isCompilation: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        releases: [Release] = [],
        artist: Artist? = nil
    ) {
        self.id = id
        self.artistId = artistId
        self.title = title
        self.sortTitle = sortTitle
        self.albumArtistName = albumArtistName
        self.composerName = composerName
        self.isCompilation = isCompilation
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.releases = releases
        self.artist = artist
    }
    
    var trackCount: Int {
        releases.reduce(0) { $0 + $1.tracks.count }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, artistId, title, sortTitle, albumArtistName, composerName, isCompilation, createdAt, updatedAt
    }
}
