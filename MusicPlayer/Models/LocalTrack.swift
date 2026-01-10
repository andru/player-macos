import Foundation

/// Represents a unique on-disk audio file
/// Identity is based on content hash for deduplication
struct LocalTrack: Identifiable, Hashable {
    let id: Int64
    var fileURL: String  // File path/URL as string for persistence
    var bookmarkData: Data?  // Security-scoped bookmark
    var contentHash: String  // Content hash for deduplication
    var fileSize: Int64?
    var mtime: Date?  // Modification time
    var duration: TimeInterval?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: Int64,
        fileURL: String,
        bookmarkData: Data? = nil,
        contentHash: String,
        fileSize: Int64? = nil,
        mtime: Date? = nil,
        duration: TimeInterval? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.fileURL = fileURL
        self.bookmarkData = bookmarkData
        self.contentHash = contentHash
        self.fileSize = fileSize
        self.mtime = mtime
        self.duration = duration
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id, fileURL, bookmarkData, contentHash, fileSize, mtime, duration, createdAt, updatedAt
    }
}
