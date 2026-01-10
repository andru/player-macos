import GRDB
import Foundation

final class GRDBLocalTrackRepository: LocalTrackRepository {
    let dbWriter: any DatabaseWriter
    
    init(dbWriter: any DatabaseWriter) {
        self.dbWriter = dbWriter
    }
    
    func saveLocalTrack(_ localTrack: LocalTrack) async throws -> LocalTrack {
        try await dbWriter.write { db in
            var record = LocalTrackRecord.from(localTrack)
            try record.save(db)
            return record.toLocalTrack()
        }
    }
    
    func findLocalTrack(byContentHash contentHash: String) async throws -> LocalTrack? {
        try await dbWriter.read { db in
            guard let record = try LocalTrackRecord
                .filter(Column("contentHash") == contentHash)
                .fetchOne(db) else {
                return nil
            }
            return record.toLocalTrack()
        }
    }
    
    func findLocalTrack(byFileURL fileURL: String) async throws -> LocalTrack? {
        try await dbWriter.read { db in
            guard let record = try LocalTrackRecord
                .filter(Column("fileURL") == fileURL)
                .fetchOne(db) else {
                return nil
            }
            return record.toLocalTrack()
        }
    }
    
    func loadLocalTracks() async throws -> [LocalTrack] {
        try await dbWriter.read { db in
            let records = try LocalTrackRecord.fetchAll(db)
            return records.map { $0.toLocalTrack() }
        }
    }
}

final class GRDBLocalTrackTagsRepository: LocalTrackTagsRepository {
    let dbWriter: any DatabaseWriter
    
    init(dbWriter: any DatabaseWriter) {
        self.dbWriter = dbWriter
    }
    
    func saveLocalTrackTags(_ tags: LocalTrackTags) async throws -> LocalTrackTags {
        try await dbWriter.write { db in
            var record = LocalTrackTagsRecord.from(tags)
            try record.save(db)
            return record.toLocalTrackTags()
        }
    }
    
    func loadLocalTrackTags(forLocalTrackId localTrackId: Int64) async throws -> LocalTrackTags? {
        try await dbWriter.read { db in
            guard let record = try LocalTrackTagsRecord
                .filter(Column("localTrackId") == localTrackId)
                .fetchOne(db) else {
                return nil
            }
            return record.toLocalTrackTags()
        }
    }
    
    func loadAllLocalTrackTags() async throws -> [LocalTrackTags] {
        try await dbWriter.read { db in
            let records = try LocalTrackTagsRecord.fetchAll(db)
            return records.map { $0.toLocalTrackTags() }
        }
    }
}

final class GRDBLibraryTrackRepository: LibraryTrackRepository {
    let dbWriter: any DatabaseWriter
    
    init(dbWriter: any DatabaseWriter) {
        self.dbWriter = dbWriter
    }
    
    func saveLibraryTrack(_ libraryTrack: LibraryTrack) async throws -> LibraryTrack {
        try await dbWriter.write { db in
            var record = LibraryTrackRecord.from(libraryTrack)
            try record.save(db)
            return record.toLibraryTrack()
        }
    }
    
    func loadLibraryTrack(id: Int64) async throws -> LibraryTrack? {
        try await dbWriter.read { db in
            guard let record = try LibraryTrackRecord.fetchOne(db, key: id) else {
                return nil
            }
            return record.toLibraryTrack()
        }
    }
    
    func loadLibraryTracks() async throws -> [LibraryTrack] {
        try await dbWriter.read { db in
            let records = try LibraryTrackRecord.fetchAll(db)
            return records.map { $0.toLibraryTrack() }
        }
    }
    
    func findLibraryTrack(byLocalTrackId localTrackId: Int64) async throws -> LibraryTrack? {
        try await dbWriter.read { db in
            guard let record = try LibraryTrackRecord
                .filter(Column("localTrackId") == localTrackId)
                .fetchOne(db) else {
                return nil
            }
            return record.toLibraryTrack()
        }
    }
}

final class GRDBTrackMatchRepository: TrackMatchRepository {
    let dbWriter: any DatabaseWriter
    
    init(dbWriter: any DatabaseWriter) {
        self.dbWriter = dbWriter
    }
    
    func saveTrackMatch(_ trackMatch: TrackMatch) async throws -> TrackMatch {
        try await dbWriter.write { db in
            var record = TrackMatchRecord.from(trackMatch)
            try record.save(db)
            return record.toTrackMatch()
        }
    }
    
    func loadTrackMatches(forLibraryTrackId libraryTrackId: Int64) async throws -> [TrackMatch] {
        try await dbWriter.read { db in
            let records = try TrackMatchRecord
                .filter(Column("libraryTrackId") == libraryTrackId)
                .fetchAll(db)
            return records.map { $0.toTrackMatch() }
        }
    }
    
    func loadAllTrackMatches() async throws -> [TrackMatch] {
        try await dbWriter.read { db in
            let records = try TrackMatchRecord.fetchAll(db)
            return records.map { $0.toTrackMatch() }
        }
    }
}
