import Foundation
import GRDB

class GRDBMediumRepository: MediumRepository {
    var dbWriter: DatabaseWriter
    
    init(dbWriter: DatabaseWriter) {
        self.dbWriter = dbWriter
    }
    
    
    func loadMedia() async throws -> [Medium] {
        return try await dbWriter.read { db in
            let records = try MediumRecord.fetchAll(db)
            return records.map { $0.toMedium() }
        }
    }
    
    func loadMedia(forReleaseId releaseId: Int64) async throws -> [Medium] {
        return try await dbWriter.read { db in
            let records = try MediumRecord
                .filter(Column("releaseId") == releaseId)
                .order(Column("position"))
                .fetchAll(db)
            return records.map { $0.toMedium() }
        }
    }
    
    func loadMedium(id: Int64) async throws -> Medium? {
        return try await dbWriter.read { db in
            guard let record = try MediumRecord.fetchOne(db, key: id) else {
                return nil
            }
            return record.toMedium()
        }
    }
    
    func saveMedium(_ medium: Medium) async throws -> Medium {
        return try await dbWriter.write { db in
            var record = MediumRecord(from: medium)
            try record.save(db)
            return record.toMedium()
        }
    }
    
    func findMedium(releaseId: Int64, position: Int) async throws -> Medium? {
        return try await dbWriter.read { db in
            if let record = try MediumRecord
                .filter(Column("releaseId") == releaseId && Column("position") == position)
                .fetchOne(db) {
                return record.toMedium()
            }
            return nil
        }
    }
    
    func upsertMedium(releaseId: Int64, position: Int, format: String?, title: String?) async throws -> Medium {
        if let existing = try await findMedium(releaseId: releaseId, position: position) {
            return existing
        }
        
        let newMedium = Medium(
            id: 0,
            releaseId: releaseId,
            position: position,
            format: format,
            title: title,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        return try await saveMedium(newMedium)
    }
    
}
