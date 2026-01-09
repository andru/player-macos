import Foundation
import GRDB

class GRDBCollectionRepository: CollectionRepository {
    var dbWriter: DatabaseWriter
    
    init(dbWriter: DatabaseWriter) {
        self.dbWriter = dbWriter
    }
    
    
    func loadDigitalFiles() async throws -> [DigitalFile] {
        return try await dbWriter.read { db in
            let records = try DigitalFileRecord.fetchAll(db)
            return records.map { $0.toDigitalFile() }
        }
    }
    
    func loadDigitalFiles(forRecordingId recordingId: Int64) async throws -> [DigitalFile] {
        return try await dbWriter.read { db in
            let sql = """
                SELECT df.* FROM digital_files df
                INNER JOIN recording_digital_file rdf ON rdf.digitalFileId = df.id
                WHERE rdf.recordingId = ?
            """
            let records = try DigitalFileRecord.fetchAll(db, sql: sql, arguments: [recordingId])
            return records.map { $0.toDigitalFile() }
        }
    }
    
    func loadDigitalFile(id: Int64) async throws -> DigitalFile? {
        return try await dbWriter.read { db in
            guard let record = try DigitalFileRecord.fetchOne(db, key: id) else {
                return nil
            }
            return record.toDigitalFile()
        }
    }
    
    func saveDigitalFile(_ digitalFile: DigitalFile) async throws -> DigitalFile {
        return try await dbWriter.write { db in
            var record = DigitalFileRecord(from: digitalFile)
            try record.save(db)
            return record.toDigitalFile()
        }
    }
    
    func findDigitalFile(byFileURL fileURL: URL) async throws -> DigitalFile? {
        return try await dbWriter.read { db in
            if let record = try DigitalFileRecord
                .filter(Column("fileURL") == fileURL.path)
                .fetchOne(db) {
                return record.toDigitalFile()
            }
            return nil
        }
    }
}
