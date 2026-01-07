import Foundation

// MARK: - Core Domain Model (iOS/macOS portable)

struct Album: Identifiable, Hashable {
    var id: String {
        // Use shared key generation to ensure consistency
        Album.makeKey(name: name, albumArtist: albumArtist, artist: artist)
    }
    var name: String
    var artist: String
    var albumArtist: String?
    var artworkURL: URL?
    var artworkData: Data?
    var tracks: [Track]
    var year: Int?
    
    init(name: String, artist: String, albumArtist: String? = nil, artworkURL: URL? = nil, artworkData: Data? = nil, tracks: [Track] = [], year: Int? = nil) {
        self.name = name
        self.artist = artist
        self.albumArtist = albumArtist
        self.artworkURL = artworkURL
        self.artworkData = artworkData
        self.tracks = tracks
        self.year = year
    }
    
    /// Generate a stable key for an album based on its name and artist
    /// Uses :: delimiter to avoid collision issues with hyphens in metadata
    static func makeKey(name: String, albumArtist: String?, artist: String) -> String {
        "\(name)::\(albumArtist ?? artist)"
    }
}
