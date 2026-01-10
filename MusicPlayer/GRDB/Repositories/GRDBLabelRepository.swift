import Foundation
import GRDB

class GRDBLabelRepository: LabelRepository {
    var dbWriter: DatabaseWriter
    
    init(dbWriter: DatabaseWriter) {
        self.dbWriter = dbWriter
    }
    
    
    func loadLabels() async throws -> [Label] {
        return try await dbWriter.read { db in
            let records = try LabelRecord
                .order(Column("name"))
                .fetchAll(db)
            return records.map { $0.toLabel() }
        }
    }
    
    func loadLabel(id: Int64) async throws -> Label? {
        return try await dbWriter.read { db in
            guard let record = try LabelRecord.fetchOne(db, key: id) else {
                return nil
            }
            return record.toLabel()
        }
    }
    
    func saveLabel(_ label: Label) async throws -> Label {
        return try await dbWriter.write { db in
            var record = LabelRecord(from: label)
            try record.save(db)
            return record.toLabel()
        }
    }
    
    func findLabel(byName name: String) async throws -> Label? {
        return try await dbWriter.read { db in
            if let record = try LabelRecord
                .filter(Column("name") == name)
                .fetchOne(db) {
                return record.toLabel()
            }
            return nil
        }
    }
    
    func upsertLabel(name: String, sortName: String?) async throws -> Label {
        if let existing = try await findLabel(byName: name) {
            return existing
        }
        
        let newLabel = Label(
            id: 0,
            name: name,
            sortName: sortName,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        return try await saveLabel(newLabel)
    }
    
}
