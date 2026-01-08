import Foundation

/// Legacy track structure for backward compatibility with existing UI code
/// This maps the new database entities (Track + DigitalFile) to the old Track interface
struct LegacyTrack: Identifiable, Codable, Hashable {
    let id: Int64
    var title: String
    var artist: String
    var album: String
    var albumArtist: String?
    var duration: TimeInterval
    var fileURL: URL
    var artworkURL: URL?
    var artworkData: Data?
    var genre: String?
    var year: Int?
    var trackNumber: Int?
    
    // Internal reference to the new track ID
    var trackId: Int64 { id }
    
    init(id: Int64, title: String, artist: String, album: String, albumArtist: String? = nil, duration: TimeInterval, fileURL: URL, artworkURL: URL? = nil, artworkData: Data? = nil, genre: String? = nil, year: Int? = nil, trackNumber: Int? = nil) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.albumArtist = albumArtist
        self.duration = duration
        self.fileURL = fileURL
        self.artworkURL = artworkURL
        self.artworkData = artworkData
        self.genre = genre
        self.year = year
        self.trackNumber = trackNumber
    }
    
    /// Create a LegacyTrack from new schema entities
    init(track: Track, release: Release?, album: Album?, digitalFile: DigitalFile?) {
        self.id = track.id
        self.title = track.title
        self.artist = track.artistName
        self.album = album?.title ?? "Unknown Album"
        self.albumArtist = track.albumArtistName ?? album?.albumArtistName
        self.duration = track.duration ?? 0
        self.fileURL = digitalFile?.fileURL ?? URL(fileURLWithPath: "/unknown")
        self.artworkURL = nil
        self.artworkData = digitalFile?.artworkData
        self.genre = track.genre
        self.year = release?.year
        self.trackNumber = track.trackNumber
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
