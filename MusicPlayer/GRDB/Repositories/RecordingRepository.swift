import Foundation
import GRDB

class GRDBRecordingRepository: RecordingRepository {
    var dbWriter: DatabaseWriter
    
    init(dbWriter: DatabaseWriter) {
        self.dbWriter = dbWriter
    }
    
    
    func loadRecordings() async throws -> [Recording] {
        return try await dbWriter.read { db in
            let records = try RecordingRecord
                .order(Column("title"))
                .fetchAll(db)
            return records.map { $0.toRecording() }
        }
    }
    
    func loadRecording(id: Int64) async throws -> Recording? {
        return try await dbWriter.read { db in
            guard let record = try RecordingRecord.fetchOne(db, key: id) else {
                return nil
            }
            return record.toRecording()
        }
    }
    
    func saveRecording(_ recording: Recording) async throws -> Recording {
        return try await dbWriter.write { db in
            var record = RecordingRecord(from: recording)
            try record.save(db)
            return record.toRecording()
        }
    }
    
    func findRecording(title: String, duration: TimeInterval?) async throws -> Recording? {
        return try await dbWriter.read { db in
            var query = RecordingRecord.filter(Column("title") == title)
            
            if let duration = duration {
                // Match within 1 second tolerance
                query = query.filter(
                    Column("duration") >= (duration - 1.0) &&
                    Column("duration") <= (duration + 1.0)
                )
            }
            
            if let record = try query.fetchOne(db) {
                return record.toRecording()
            }
            return nil
        }
    }
    
    func upsertRecording(title: String, duration: TimeInterval?, workIds: [Int64], artistIds: [Int64]) async throws -> Recording {
        if let existing = try await findRecording(title: title, duration: duration) {
            return existing
        }
        
        return try await dbWriter.write { db in
            var recordingRecord = RecordingRecord(id: nil, title: title, duration: duration)
            try recordingRecord.save(db)
            
            let recordingId = recordingRecord.id!
            
            // Link works
            for workId in workIds {
                try db.execute(
                    sql: "INSERT INTO recording_work (recordingId, workId) VALUES (?, ?)",
                    arguments: [recordingId, workId]
                )
            }
            
            // Link artists
            for artistId in artistIds {
                try db.execute(
                    sql: "INSERT INTO recording_artist (recordingId, artistId) VALUES (?, ?)",
                    arguments: [recordingId, artistId]
                )
            }
            
            return recordingRecord.toRecording()
        }
    }
    
    func linkRecordingToDigitalFile(recordingId: Int64, digitalFileId: Int64) async throws {
        try await dbWriter.write { db in
            try db.execute(
                sql: "INSERT OR IGNORE INTO recording_digital_file (recordingId, digitalFileId) VALUES (?, ?)",
                arguments: [recordingId, digitalFileId]
            )
        }
    }
    
    func loadRecordingsWithoutDigitalFiles() async throws -> [Recording] {
        return try await dbWriter.read { db in
            let sql = """
                SELECT r.* FROM recordings r
                LEFT JOIN recording_digital_file rdf ON rdf.recordingId = r.id
                WHERE rdf.digitalFileId IS NULL
            """
            let records = try RecordingRecord.fetchAll(db, sql: sql)
            return records.map { $0.toRecording() }
        }
    }
    
    func loadRecordingsWithDigitalFiles() async throws -> [Recording] {
        return try await dbWriter.read { db in
            let sql = """
                SELECT DISTINCT r.* FROM recordings r
                INNER JOIN recording_digital_file rdf ON rdf.recordingId = r.id
            """
            let records = try RecordingRecord.fetchAll(db, sql: sql)
            return records.map { $0.toRecording() }
        }
    }
    
}
