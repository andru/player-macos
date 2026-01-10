import Foundation

/// Represents a unique on-disk audio file
/// Identity is based on content hash for deduplication
struct LocalTrack: Identifiable, Sendable {
    let id: Int64
    let contentHash: String
    let fileURL: String
    let bookmarkData: Data?
    let fileSize: Int64?
    let modifiedAt: Date?
    let duration: TimeInterval?
    let addedAt: Date
    let lastScannedAt: Date
    let createdAt: Date
    let updatedAt: Date
    
    init(
        id: Int64 = 0,
        contentHash: String,
        fileURL: String,
        bookmarkData: Data? = nil,
        fileSize: Int64? = nil,
        modifiedAt: Date? = nil,
        duration: TimeInterval? = nil,
        addedAt: Date = Date(),
        lastScannedAt: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.contentHash = contentHash
        self.fileURL = fileURL
        self.bookmarkData = bookmarkData
        self.fileSize = fileSize
        self.modifiedAt = modifiedAt
        self.duration = duration
        self.addedAt = addedAt
        self.lastScannedAt = lastScannedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
