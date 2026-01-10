import Foundation
import GRDB

/// GRDB-based implementation of Artist repository
class GRDBArtistRepository: ArtistRepository {
    var dbWriter: DatabaseWriter
    
    init(dbWriter: DatabaseWriter) {
        self.dbWriter = dbWriter
    }
    
    func loadArtists() async throws -> [Artist] {
        return try await dbWriter.read { db in
            let records = try ArtistRecord
                .order(Column("name"))
                .fetchAll(db)
            return records.map { $0.toArtist() }
        }
    }
    
    func loadArtist(id: Int64) async throws -> Artist? {
        return try await dbWriter.read { db in
            guard let record = try ArtistRecord.fetchOne(db, key: id) else {
                return nil
            }
            
            return record.toArtist()
        }
    }
    
    func saveArtist(_ artist: Artist) async throws -> Artist {
        return try await dbWriter.write { db in
            var record = ArtistRecord(from: artist)
            try record.save(db)
            return record.toArtist()
        }
    }
    
    func findArtist(byName name: String) async throws -> Artist? {
        return try await dbWriter.read { db in
            if let record = try ArtistRecord
                .filter(Column("name") == name)
                .fetchOne(db) {
                return record.toArtist()
            }
            return nil
        }
    }
    
    func upsertArtist(name: String, sortName: String?) async throws -> Artist {
        let newArtist = Artist(
            id: 0,
            name: name,
            sortName: sortName,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        return try await saveArtist(newArtist)
    }
}
