import Foundation
import GRDB

class GRDBWorkRepository: WorkRepository {
    var dbWriter: DatabaseWriter
    
    init(dbWriter: DatabaseWriter) {
        self.dbWriter = dbWriter
    }
    
    func loadWorks() async throws -> [Work] {
        return try await dbWriter.read { db in
            let records = try WorkRecord
                .order(Column("title"))
                .fetchAll(db)
            return records.map { $0.toWork() }
        }
    }
    
    func loadWork(id: Int64) async throws -> Work? {
        return try await dbWriter.read { db in
            guard let record = try WorkRecord.fetchOne(db, key: id) else {
                return nil
            }
            return record.toWork()
        }
    }
    
    func saveWork(_ work: Work) async throws -> Work {
        return try await dbWriter.write { db in
            var record = WorkRecord(from: work)
            try record.save(db)
            return record.toWork()
        }
    }
    
    func findWork(title: String, primaryArtistId: Int64) async throws -> Work? {
        return try await dbWriter.read { db in
            // Find work by title with artist link
            let sql = """
                SELECT w.* FROM works w
                INNER JOIN work_artist wa ON wa.workId = w.id
                WHERE w.title = ? AND wa.artistId = ?
                LIMIT 1
            """
            if let record = try WorkRecord.fetchOne(db, sql: sql, arguments: [title, primaryArtistId]) {
                return record.toWork()
            }
            return nil
        }
    }
    
    func upsertWork(title: String, artistIds: [Int64]) async throws -> Work {
        // Try to find existing work
        if let primaryArtistId = artistIds.first,
           let existing = try await findWork(title: title, primaryArtistId: primaryArtistId) {
            return existing
        }
        
        // Create new work
        return try await dbWriter.write { db in
            var workRecord = WorkRecord(id: nil, title: title)
            try workRecord.save(db)
            
            let workId = workRecord.id!
            
            // Link artists
            for artistId in artistIds {
                try db.execute(
                    sql: "INSERT INTO work_artist (workId, artistId) VALUES (?, ?)",
                    arguments: [workId, artistId]
                )
            }
            
            return workRecord.toWork()
        }
    }
    
}
