import Foundation
import GRDB

class GRDBReleaseGroupRepository: ReleaseGroupRepository {
    var dbWriter: DatabaseWriter
    
    init(dbWriter: DatabaseWriter) {
        self.dbWriter = dbWriter
    }
    
    
    func loadReleaseGroups() async throws -> [ReleaseGroup] {
        return try await dbWriter.read { db in
            let records = try ReleaseGroupRecord
                .order(Column("title"))
                .fetchAll(db)
            return records.map { $0.toReleaseGroup() }
        }
    }
    
    func loadReleaseGroups(forArtistId artistId: Int64) async throws -> [ReleaseGroup] {
        return try await dbWriter.read { db in
            let records = try ReleaseGroupRecord
                .filter(Column("primaryArtistId") == artistId)
                .order(Column("title"))
                .fetchAll(db)
            return records.map { $0.toReleaseGroup() }
        }
    }
    
    func loadReleaseGroup(id: Int64) async throws -> ReleaseGroup? {
        return try await dbWriter.read { db in
            guard let record = try ReleaseGroupRecord.fetchOne(db, key: id) else {
                return nil
            }

            return record.toReleaseGroup()
        }
    }
    
    func saveReleaseGroup(_ releaseGroup: ReleaseGroup) async throws -> ReleaseGroup {
        return try await dbWriter.write { db in
            var record = ReleaseGroupRecord(from: releaseGroup)
            try record.save(db)
            return record.toReleaseGroup()
        }
    }
    
    func findReleaseGroup(title: String, primaryArtistId: Int64?) async throws -> ReleaseGroup? {
        return try await dbWriter.read { db in
            var query = ReleaseGroupRecord.filter(Column("title") == title)
            
            if let artistId = primaryArtistId {
                query = query.filter(Column("primaryArtistId") == artistId)
            } else {
                query = query.filter(Column("primaryArtistId") == nil)
            }
            
            if let record = try query.fetchOne(db) {
                return record.toReleaseGroup()
            }
            return nil
        }
    }
    
    func upsertReleaseGroup(title: String, primaryArtistId: Int64?, isCompilation: Bool) async throws -> ReleaseGroup {
        if let existing = try await findReleaseGroup(title: title, primaryArtistId: primaryArtistId) {
            return existing
        }
        
        let newReleaseGroup = ReleaseGroup(
            id: 0,
            title: title,
            primaryArtistId: primaryArtistId,
            isCompilation: isCompilation,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        return try await saveReleaseGroup(newReleaseGroup)
    }
    
}
