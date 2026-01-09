import Foundation
import GRDB

class GRDBTrackRepository: TrackRepository {
    var dbWriter: DatabaseWriter
    
    init(dbWriter: DatabaseWriter) {
        self.dbWriter = dbWriter
    }
    
    
    func loadTracks() async throws -> [Track] {
        return try await dbWriter.read { db in
            let records = try TrackRecord.fetchAll(db)
            return records.map { $0.toTrack() }
        }
    }
    
    func loadTracks(forMediumId mediumId: Int64) async throws -> [Track] {
        return try await dbWriter.read { db in
            let records = try TrackRecord
                .filter(Column("mediumId") == mediumId)
                .order(Column("position"))
                .fetchAll(db)
            return records.map { $0.toTrack() }
        }
    }
    
    func loadTrack(id: Int64) async throws -> Track? {
        return try await dbWriter.read { db in
            guard let record = try TrackRecord.fetchOne(db, key: id) else {
                return nil
            }
            return record.toTrack()
        }
    }
    
    func saveTrack(_ track: Track) async throws -> Track {
        return try await dbWriter.write { db in
            var record = TrackRecord(from: track)
            try record.save(db)
            return record.toTrack()
        }
    }
    
    func saveTracks(_ tracks: [Track]) async throws {
        try await dbWriter.write { db in
            for track in tracks {
                var record = TrackRecord(from: track)
                try record.save(db)
            }
        }
    }
    
}
