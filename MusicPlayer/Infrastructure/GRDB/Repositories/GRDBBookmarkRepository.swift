import Foundation
import GRDB

actor GRDBBookmarkStore: BookmarkStoring, BookmarkRegistering {
    private let dbWriter: any DatabaseWriter

    init(dbWriter: any DatabaseWriter) {
        self.dbWriter = dbWriter
    }

    func bookmarkData(for id: LocationID) async throws -> Data {
        try await dbWriter.read { db in
            guard let record = try FileLocationRecord.fetchOne(db, key: id.rawValue) else {
                throw BookmarkStoreError.notFound(id)
            }
            return record.bookmarkData
        }
    }

    /// Saves bookmark data for an existing location (refresh) or creates it if missing.
    /// Preserves `createdAt` on updates.
    func saveBookmarkData(_ data: Data, for id: LocationID) async throws {
        let now = Date()

        try await dbWriter.write { db in
            if var existing = try FileLocationRecord.fetchOne(db, key: id.rawValue) {
                
                existing = existing.withUpdatedBookmarkData(data)

                try existing.update(db)
            } else {
                let new = FileLocationRecord(
                    id: id.rawValue,
                    bookmarkData: data,
                    createdAt: now,
                    updatedAt: now
                )
                try new.insert(db)
            }
        }
    }

    /// Registers a user-picked URL and returns a stable LocationID that can be stored elsewhere.
    func registerLocation(url: URL) async throws -> LocationID {
        let id = LocationID(rawValue: UUID().uuidString)

        let bookmarkData: Data
        do {
            bookmarkData = try url.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
        } catch {
            throw BookmarkStoreError.invalidBookmarkCreation(url)
        }

        try await saveBookmarkData(bookmarkData, for: id)
        return id
    }

    // Optional helper (often useful):
    func deleteLocation(id: LocationID) async throws {
        try await dbWriter.write { db in
            _ = try FileLocationRecord.deleteOne(db, key: id.rawValue)
        }
    }
}
