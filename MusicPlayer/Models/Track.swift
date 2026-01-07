import Foundation

// MARK: - Core Domain Model (iOS/macOS portable)

struct Track: Identifiable, Codable, Hashable {
    let id: UUID
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
    
    init(id: UUID = UUID(), title: String, artist: String, album: String, albumArtist: String? = nil, duration: TimeInterval, fileURL: URL, artworkURL: URL? = nil, artworkData: Data? = nil, genre: String? = nil, year: Int? = nil, trackNumber: Int? = nil) {
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

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

