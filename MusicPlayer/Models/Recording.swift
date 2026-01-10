import Foundation

// MARK: - Core Domain Model (iOS/macOS portable)

struct Recording: Identifiable, Hashable {
    let id: Int64
    var title: String
    var duration: TimeInterval?
    var createdAt: Date
    var updatedAt: Date
    
    // Transient properties (not persisted, loaded via relationships)
    var works: [Work]
    var artists: [Artist]
    var digitalFiles: [DigitalFile]
    var tracks: [Track]
    
    init(
        id: Int64,
        title: String,
        duration: TimeInterval? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        works: [Work] = [],
        artists: [Artist] = [],
        digitalFiles: [DigitalFile] = [],
        tracks: [Track] = []
    ) {
        self.id = id
        self.title = title
        self.duration = duration
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.works = works
        self.artists = artists
        self.digitalFiles = digitalFiles
        self.tracks = tracks
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
        case id, title, duration, createdAt, updatedAt
    }
}
