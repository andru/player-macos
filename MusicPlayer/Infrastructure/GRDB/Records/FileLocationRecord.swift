import GRDB
import Foundation

struct FileLocationRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "file_location"

    let id: String
    let bookmarkData: Data
    let createdAt: Date
    let updatedAt: Date
    
    func withUpdatedBookmarkData(_ data: Data) -> FileLocationRecord {
        return FileLocationRecord(
            id: id,
            bookmarkData: data,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }
}
