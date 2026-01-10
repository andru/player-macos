import Foundation

// MARK: - Core Domain Model (iOS/macOS portable)

/// Local-only entity representing a file on disk
struct DigitalFile: Identifiable, Hashable {
    let id: Int64
    var fileURL: URL
    var bookmarkData: Data?
    var fileHash: String?
    var fileSize: Int64?
    var addedAt: Date
    var lastScannedAt: Date?
    var metadataJSON: String?
    var artworkData: Data?
    
    // Transient properties
    var recordings: [Recording]
    
    init(
        id: Int64,
        fileURL: URL,
        bookmarkData: Data? = nil,
        fileHash: String? = nil,
        fileSize: Int64? = nil,
        addedAt: Date = Date(),
        lastScannedAt: Date? = nil,
        metadataJSON: String? = nil,
        artworkData: Data? = nil,
        recordings: [Recording] = []
    ) {
        self.id = id
        self.fileURL = fileURL
        self.bookmarkData = bookmarkData
        self.fileHash = fileHash
        self.fileSize = fileSize
        self.addedAt = addedAt
        self.lastScannedAt = lastScannedAt
        self.metadataJSON = metadataJSON
        self.artworkData = artworkData
        self.recordings = recordings
    }
    
    enum CodingKeys: String, CodingKey {
        case id, fileURL, bookmarkData, fileHash, fileSize
        case addedAt, lastScannedAt, metadataJSON, artworkData
    }
}
