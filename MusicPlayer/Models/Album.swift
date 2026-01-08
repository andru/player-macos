import Foundation

// MARK: - UI/View Model (maps ReleaseGroup for compatibility)

/// Album is a UI/view model that wraps a ReleaseGroup for backward compatibility
/// This allows the UI to continue using "Album" while the persistence layer uses ReleaseGroup
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
        // Derive artistName from artist or use primary artist name
        self.artistName = artist?.name ?? albumArtistName ?? "Unknown Artist"
    }
    
    /// Create an Album view model from a ReleaseGroup
    init(from releaseGroup: ReleaseGroup, artistName: String? = nil) {
        self.id = releaseGroup.id
        self.artistId = releaseGroup.primaryArtistId ?? 0
        self.title = releaseGroup.title
        self.sortTitle = nil
        self.albumArtistName = artistName
        self.composerName = nil
        self.isCompilation = releaseGroup.isCompilation
        self.createdAt = releaseGroup.createdAt
        self.updatedAt = releaseGroup.updatedAt
        self.releases = releaseGroup.releases
        self.artist = releaseGroup.primaryArtist
        self.artistName = artistName ?? releaseGroup.primaryArtist?.name ?? "Unknown Artist"
    }
    
    var trackCount: Int {
        releases.reduce(0) { $0 + $1.trackCount }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, artistId, title, sortTitle, albumArtistName, composerName, isCompilation, createdAt, updatedAt
    }
}
