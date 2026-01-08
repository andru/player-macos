import Foundation

// MARK: - Core Domain Model (iOS/macOS portable)

struct DigitalFile: Identifiable, Codable, Hashable {
    let id: Int64
    var trackId: Int64
    var fileURL: URL
    var bookmarkData: Data?
    var fileHash: String?
    var fileSize: Int64?
    var addedAt: Date
    var lastScannedAt: Date?
    var metadataJSON: String?
    var artworkData: Data?
    
    // Transient properties
    var track: Track?
    
    init(
        id: Int64,
        trackId: Int64,
        fileURL: URL,
        bookmarkData: Data? = nil,
        fileHash: String? = nil,
        fileSize: Int64? = nil,
        addedAt: Date = Date(),
        lastScannedAt: Date? = nil,
        metadataJSON: String? = nil,
        artworkData: Data? = nil,
        track: Track? = nil
    ) {
        self.id = id
        self.trackId = trackId
        self.fileURL = fileURL
        self.bookmarkData = bookmarkData
        self.fileHash = fileHash
        self.fileSize = fileSize
        self.addedAt = addedAt
        self.lastScannedAt = lastScannedAt
        self.metadataJSON = metadataJSON
        self.artworkData = artworkData
        self.track = track
    }
    
    enum CodingKeys: String, CodingKey {
        case id, trackId, fileURL, bookmarkData, fileHash, fileSize
        case addedAt, lastScannedAt, metadataJSON, artworkData
    }
}
