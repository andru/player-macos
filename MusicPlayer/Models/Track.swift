import Foundation

// MARK: - Core Domain Model (iOS/macOS portable)

struct Track: Identifiable, Hashable {
    let id: Int64
    var releaseId: Int64
    var discNumber: Int
    var trackNumber: Int?
    var title: String
    var duration: TimeInterval?
    var artistName: String
    var albumArtistName: String?
    var composerName: String?
    var genre: String?
    var createdAt: Date
    var updatedAt: Date
    
    // Transient properties (not persisted, loaded via relationships)
    var digitalFiles: [DigitalFile]
    var release: Release?
    
    init(
        id: Int64,
        releaseId: Int64,
        discNumber: Int = 1,
        trackNumber: Int? = nil,
        title: String,
        duration: TimeInterval? = nil,
        artistName: String,
        albumArtistName: String? = nil,
        composerName: String? = nil,
        genre: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        digitalFiles: [DigitalFile] = [],
        release: Release? = nil
    ) {
        self.id = id
        self.releaseId = releaseId
        self.discNumber = discNumber
        self.trackNumber = trackNumber
        self.title = title
        self.duration = duration
        self.artistName = artistName
        self.albumArtistName = albumArtistName
        self.composerName = composerName
        self.genre = genre
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.digitalFiles = digitalFiles
        self.release = release
    }

    var formattedDuration: String {
        guard let duration = duration else { return "--:--" }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var hasDigitalFiles: Bool {
        !digitalFiles.isEmpty
    }
    
    enum CodingKeys: String, CodingKey {
        case id, releaseId, discNumber, trackNumber, title, duration
        case artistName, albumArtistName, composerName, genre, createdAt, updatedAt
    }
}

