import Foundation
import GRDB

final class GRDBLocalTrackRepository: LocalTrackRepository {
    let dbWriter: any DatabaseWriter
    
    init(dbWriter: any DatabaseWriter) {
        self.dbWriter = dbWriter
    }
    
    func loadLocalTracks() async throws -> [LocalTrack] {
        try await dbWriter.read { db in
            try LocalTrackRecord.fetchAll(db).map { $0.toLocalTrack() }
        }
    }
    
    func loadLocalTrack(id: Int64) async throws -> LocalTrack? {
        try await dbWriter.read { db in
            try LocalTrackRecord.fetchOne(db, key: id)?.toLocalTrack()
        }
    }
    
    func findLocalTrack(byContentHash hash: String) async throws -> LocalTrack? {
        try await dbWriter.read { db in
            try LocalTrackRecord
                .filter(Column("contentHash") == hash)
                .fetchOne(db)?
                .toLocalTrack()
        }
    }
    
    func saveLocalTrack(_ localTrack: LocalTrack) async throws -> LocalTrack {
        try await dbWriter.write { db in
            var record = LocalTrackRecord(from: localTrack)
            try record.save(db)
            return record.toLocalTrack()
        }
    }
    
    func upsertLocalTrack(
        contentHash: String,
        fileURL: String,
        bookmarkData: Data?,
        fileSize: Int64?,
        modifiedAt: Date?,
        duration: TimeInterval?
    ) async throws -> LocalTrack {
        // Check if already exists
        if let existing = try await findLocalTrack(byContentHash: contentHash) {
            // Update existing record
            let updated = LocalTrack(
                id: existing.id,
                contentHash: contentHash,
                fileURL: fileURL,
                bookmarkData: bookmarkData,
                fileSize: fileSize,
                modifiedAt: modifiedAt,
                duration: duration,
                addedAt: existing.addedAt,
                lastScannedAt: Date(),
                createdAt: existing.createdAt,
                updatedAt: Date()
            )
            return try await saveLocalTrack(updated)
        } else {
            // Create new record
            let new = LocalTrack(
                contentHash: contentHash,
                fileURL: fileURL,
                bookmarkData: bookmarkData,
                fileSize: fileSize,
                modifiedAt: modifiedAt,
                duration: duration
            )
            return try await saveLocalTrack(new)
        }
    }
}

final class GRDBLocalTrackTagsRepository: LocalTrackTagsRepository {
    let dbWriter: any DatabaseWriter
    
    init(dbWriter: any DatabaseWriter) {
        self.dbWriter = dbWriter
    }
    
    func loadAllTags() async throws -> [LocalTrackTags] {
        try await dbWriter.read { db in
            try LocalTrackTagsRecord.fetchAll(db).map { $0.toLocalTrackTags() }
        }
    }
    
    func loadTags(forLocalTrackId localTrackId: Int64) async throws -> [LocalTrackTags] {
        try await dbWriter.read { db in
            try LocalTrackTagsRecord
                .filter(Column("localTrackId") == localTrackId)
                .fetchAll(db)
                .map { $0.toLocalTrackTags() }
        }
    }
    
    func loadTags(id: Int64) async throws -> LocalTrackTags? {
        try await dbWriter.read { db in
            try LocalTrackTagsRecord.fetchOne(db, key: id)?.toLocalTrackTags()
        }
    }
    
    func saveTags(_ tags: LocalTrackTags) async throws -> LocalTrackTags {
        try await dbWriter.write { db in
            var record = LocalTrackTagsRecord(from: tags)
            try record.save(db)
            return record.toLocalTrackTags()
        }
    }
}

final class GRDBLibraryTrackRepository: LibraryTrackRepository {
    let dbWriter: any DatabaseWriter
    
    init(dbWriter: any DatabaseWriter) {
        self.dbWriter = dbWriter
    }
    
    func loadLibraryTracks() async throws -> [LibraryTrack] {
        try await dbWriter.read { db in
            try LibraryTrackRecord.fetchAll(db).map { $0.toLibraryTrack() }
        }
    }
    
    func loadLibraryTrack(id: Int64) async throws -> LibraryTrack? {
        try await dbWriter.read { db in
            try LibraryTrackRecord.fetchOne(db, key: id)?.toLibraryTrack()
        }
    }
    
    func findLibraryTrack(byLocalTrackId localTrackId: Int64) async throws -> LibraryTrack? {
        try await dbWriter.read { db in
            try LibraryTrackRecord
                .filter(Column("localTrackId") == localTrackId)
                .fetchOne(db)?
                .toLibraryTrack()
        }
    }
    
    func saveLibraryTrack(_ libraryTrack: LibraryTrack) async throws -> LibraryTrack {
        try await dbWriter.write { db in
            var record = LibraryTrackRecord(from: libraryTrack)
            try record.save(db)
            return record.toLibraryTrack()
        }
    }
    
    func upsertLibraryTrack(
        localTrackId: Int64,
        localTrackTagsId: Int64
    ) async throws -> LibraryTrack {
        // Check if already exists for this local track
        if let existing = try await findLibraryTrack(byLocalTrackId: localTrackId) {
            // Update with new tags
            let updated = LibraryTrack(
                id: existing.id,
                localTrackId: localTrackId,
                localTrackTagsId: localTrackTagsId,
                addedAt: existing.addedAt,
                createdAt: existing.createdAt,
                updatedAt: Date()
            )
            return try await saveLibraryTrack(updated)
        } else {
            // Create new
            let new = LibraryTrack(
                localTrackId: localTrackId,
                localTrackTagsId: localTrackTagsId
            )
            return try await saveLibraryTrack(new)
        }
    }
}

final class GRDBTrackMatchRepository: TrackMatchRepository {
    let dbWriter: any DatabaseWriter
    
    init(dbWriter: any DatabaseWriter) {
        self.dbWriter = dbWriter
    }
    
    func loadTrackMatches() async throws -> [TrackMatch] {
        try await dbWriter.read { db in
            try TrackMatchRecord.fetchAll(db).map { $0.toTrackMatch() }
        }
    }
    
    func loadMatches(forLibraryTrackId libraryTrackId: Int64) async throws -> [TrackMatch] {
        try await dbWriter.read { db in
            try TrackMatchRecord
                .filter(Column("libraryTrackId") == libraryTrackId)
                .fetchAll(db)
                .map { $0.toTrackMatch() }
        }
    }
    
    func loadTrackMatch(id: Int64) async throws -> TrackMatch? {
        try await dbWriter.read { db in
            try TrackMatchRecord.fetchOne(db, key: id)?.toTrackMatch()
        }
    }
    
    func saveTrackMatch(_ trackMatch: TrackMatch) async throws -> TrackMatch {
        try await dbWriter.write { db in
            var record = TrackMatchRecord(from: trackMatch)
            try record.save(db)
            return record.toTrackMatch()
        }
    }
}
