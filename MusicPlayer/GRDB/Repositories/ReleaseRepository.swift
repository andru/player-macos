import Foundation
import GRDB

class GRDBReleaseRepository: ReleaseRepository {
    var dbWriter: DatabaseWriter
    
    init(dbWriter: DatabaseWriter) {
        self.dbWriter = dbWriter
    }
    
    
    func loadReleases() async throws -> [Release] {
        return try await dbWriter.read { db in
            let records = try ReleaseRecord.fetchAll(db)
            return records.map { $0.toRelease() }
        }
    }
    
    func loadReleases(forReleaseGroupId releaseGroupId: Int64) async throws -> [Release] {
        return try await dbWriter.read { db in
            let records = try ReleaseRecord
                .filter(Column("releaseGroupId") == releaseGroupId)
                .order(Column("format"), Column("year"))
                .fetchAll(db)
            return records.map { $0.toRelease() }
        }
    }
    
    func loadRelease(id: Int64) async throws -> Release? {
        return try await dbWriter.read { db in
            guard let record = try ReleaseRecord.fetchOne(db, key: id) else {
                return nil
            }
            
            return record.toRelease()
        }
    }
    
    func saveRelease(_ release: Release) async throws -> Release {
        return try await dbWriter.write { db in
            var record = ReleaseRecord(from: release)
            try record.save(db)
            return record.toRelease()
        }
    }
    
    func findRelease(releaseGroupId: Int64, format: ReleaseFormat, edition: String?, year: Int?, country: String?) async throws -> Release? {
        return try await dbWriter.read { db in
            var query = ReleaseRecord
                .filter(Column("releaseGroupId") == releaseGroupId && Column("format") == format.rawValue)
            
            if let edition = edition {
                query = query.filter(Column("edition") == edition)
            } else {
                query = query.filter(Column("edition") == nil)
            }
            
            if let year = year {
                query = query.filter(Column("year") == year)
            } else {
                query = query.filter(Column("year") == nil)
            }
            
            if let country = country {
                query = query.filter(Column("country") == country)
            } else {
                query = query.filter(Column("country") == nil)
            }
            
            if let record = try query.fetchOne(db) {
                return record.toRelease()
            }
            return nil
        }
    }
    
    func upsertRelease(releaseGroupId: Int64, format: ReleaseFormat, edition: String?, year: Int?, country: String?, catalogNumber: String?, barcode: String?) async throws -> Release {
        if let existing = try await findRelease(releaseGroupId: releaseGroupId, format: format, edition: edition, year: year, country: country) {
            return existing
        }
        
        let newRelease = Release(
            id: 0,
            releaseGroupId: releaseGroupId,
            format: format,
            edition: edition,
            year: year,
            country: country,
            catalogNumber: catalogNumber,
            barcode: barcode,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        return try await saveRelease(newRelease)
    }
    
    func getDefaultRelease(forReleaseGroupId releaseGroupId: Int64) async throws -> Release? {
        return try await dbWriter.read { db in
            // Prefer Digital format if present
            if let digital = try ReleaseRecord
                .filter(Column("releaseGroupId") == releaseGroupId && Column("format") == "Digital")
                .fetchOne(db) {
                return digital.toRelease()
            }
            
            // Otherwise return the first release for this release group
            if let any = try ReleaseRecord
                .filter(Column("releaseGroupId") == releaseGroupId)
                .fetchOne(db) {
                return any.toRelease()
            }
            
            return nil
        }
    }
    
}
