import Foundation
import GRDB

class GRDBCollectionRepository: CollectionRepository {
    var dbWriter: DatabaseWriter
    
    init(dbWriter: DatabaseWriter) {
        self.dbWriter = dbWriter
    }
    
    func loadCollections() async throws -> [Collection] {
        return try await dbWriter.read { db in
            let collectionRecords = try CollectionRecord
                .order(Column("name"))
                .fetchAll(db)
            
            var collections: [Collection] = []
            
            for collectionRecord in collectionRecords {
                let trackIdRecords = try CollectionTrackRecord
                    .filter(CollectionTrackRecord.Columns.collectionId == collectionRecord.id)
                    .order(CollectionTrackRecord.Columns.position)
                    .fetchAll(db)
                
                let trackIDs = trackIdRecords.compactMap { Int64($0.trackId) }
                
                let collection = Collection(
                    id: UUID(uuidString: collectionRecord.id) ?? UUID(),
                    name: collectionRecord.name,
                    trackIDs: trackIDs
                )
                
                collections.append(collection)
            }
            
            return collections
        }
    }
    
    func saveCollections(_ collections: [Collection]) async throws {
        try await dbWriter.write { db in
            try CollectionRecord.deleteAll(db)
            try CollectionTrackRecord.deleteAll(db)
            
            for collection in collections {
                let collectionRecord = CollectionRecord(from: collection)
                try collectionRecord.insert(db)
                
                for (index, trackID) in collection.trackIDs.enumerated() {
                    let trackRecord = CollectionTrackRecord(
                        collectionId: collection.id.uuidString,
                        trackId: String(trackID),
                        position: index
                    )
                    try trackRecord.insert(db)
                }
            }
        }
    }
}
