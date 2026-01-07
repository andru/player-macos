import Foundation
import GRDB

// MARK: - GRDB Record for Track

struct TrackRecord: Codable, FetchableRecord, PersistableRecord {
    var id: String
    var title: String
    var artist: String
    var album: String
    var albumArtist: String?
    var duration: Double
    var fileURL: String
    var artworkURL: String?
    var artworkData: Data?
    var genre: String?
    var year: Int?
    var trackNumber: Int?
    
    static let databaseTableName = "tracks"
    
    init(from track: Track) {
        self.id = track.id.uuidString
        self.title = track.title
        self.artist = track.artist
        self.album = track.album
        self.albumArtist = track.albumArtist
        self.duration = track.duration
        self.fileURL = track.fileURL.path
        self.artworkURL = track.artworkURL?.path
        self.artworkData = track.artworkData
        self.genre = track.genre
        self.year = track.year
        self.trackNumber = track.trackNumber
    }
    
    func toTrack() -> Track {
        Track(
            id: UUID(uuidString: id) ?? UUID(),
            title: title,
            artist: artist,
            album: album,
            albumArtist: albumArtist,
            duration: duration,
            fileURL: URL(fileURLWithPath: fileURL),
            artworkURL: artworkURL.map { URL(fileURLWithPath: $0) },
            artworkData: artworkData,
            genre: genre,
            year: year,
            trackNumber: trackNumber
        )
    }
}

// MARK: - GRDB Record for Collection

struct CollectionRecord: Codable, FetchableRecord, PersistableRecord {
    var id: String
    var name: String
    
    static let databaseTableName = "collections"
    
    init(from collection: Collection) {
        self.id = collection.id.uuidString
        self.name = collection.name
    }
}

// MARK: - GRDB Record for Collection-Track Association

struct CollectionTrackRecord: Codable, FetchableRecord, PersistableRecord {
    var collectionId: String
    var trackId: String
    var position: Int
    
    static let databaseTableName = "collection_tracks"
    
    enum Columns {
        static let collectionId = Column(CodingKeys.collectionId)
        static let trackId = Column(CodingKeys.trackId)
        static let position = Column(CodingKeys.position)
    }
}

// MARK: - GRDB Database Manager

/// GRDB-based implementation of track and collection repositories
class GRDBRepository: TrackRepository, CollectionRepository {
    private var dbQueue: DatabaseQueue?
    private let dbFileName = "library.db"
    
    // MARK: - Initialization
    
    /// Open database connection at the specified library bundle URL
    func openDatabase(at bundleURL: URL) async throws {
        closeDatabase()
        
        let dbURL = bundleURL
            .appendingPathComponent("Contents/Resources/")
            .appendingPathComponent(dbFileName)
        
        do {
            let dbQueue = try DatabaseQueue(path: dbURL.path)
            self.dbQueue = dbQueue
            
            // Run migrations
            try dbQueue.write { db in
                var migrator = DatabaseMigrator()
                
                // Migration v1: Initial schema
                migrator.registerMigration("v1") { db in
                    // Create tracks table
                    try db.create(table: "tracks") { t in
                        t.column("id", .text).primaryKey()
                        t.column("title", .text).notNull()
                        t.column("artist", .text).notNull()
                        t.column("album", .text).notNull()
                        t.column("albumArtist", .text)
                        t.column("duration", .double).notNull()
                        t.column("fileURL", .text).notNull()
                        t.column("artworkURL", .text)
                        t.column("artworkData", .blob)
                        t.column("genre", .text)
                        t.column("year", .integer)
                        t.column("trackNumber", .integer)
                    }
                    
                    // Create collections table
                    try db.create(table: "collections") { t in
                        t.column("id", .text).primaryKey()
                        t.column("name", .text).notNull()
                    }
                    
                    // Create collection_tracks junction table
                    try db.create(table: "collection_tracks") { t in
                        t.column("collectionId", .text).notNull()
                        t.column("trackId", .text).notNull()
                        t.column("position", .integer).notNull()
                        t.primaryKey(["collectionId", "trackId"])
                        t.foreignKey(["collectionId"], references: "collections", columns: ["id"], onDelete: .cascade)
                        t.foreignKey(["trackId"], references: "tracks", columns: ["id"], onDelete: .cascade)
                    }
                    
                    // Create indexes for better performance
                    try db.create(index: "idx_tracks_artist", on: "tracks", columns: ["artist"])
                    try db.create(index: "idx_tracks_album", on: "tracks", columns: ["album"])
                    try db.create(index: "idx_tracks_album_artist", on: "tracks", columns: ["albumArtist"])
                    try db.create(index: "idx_collection_tracks_collection", on: "collection_tracks", columns: ["collectionId"])
                }
                
                try migrator.migrate(db)
            }
        } catch {
            throw DatabaseError.openFailed(message: error.localizedDescription)
        }
    }
    
    /// Close the database connection
    func closeDatabase() {
        dbQueue = nil
    }
    
    // MARK: - TrackRepository
    
    func loadTracks() async throws -> [Track] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            let records = try TrackRecord.fetchAll(db)
            return records.map { $0.toTrack() }
        }
    }
    
    func saveTracks(_ tracks: [Track]) async throws {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        try await dbQueue.write { db in
            // Clear existing tracks
            try TrackRecord.deleteAll(db)
            
            // Insert all tracks
            for track in tracks {
                let record = TrackRecord(from: track)
                try record.insert(db)
            }
        }
    }
    
    // MARK: - CollectionRepository
    
    func loadCollections() async throws -> [Collection] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            let collectionRecords = try CollectionRecord
                .order(Column("name"))
                .fetchAll(db)
            
            var collections: [Collection] = []
            
            for collectionRecord in collectionRecords {
                // Load track IDs for this collection
                let trackIdRecords = try CollectionTrackRecord
                    .filter(CollectionTrackRecord.Columns.collectionId == collectionRecord.id)
                    .order(CollectionTrackRecord.Columns.position)
                    .fetchAll(db)
                
                let trackIDs = trackIdRecords.compactMap { UUID(uuidString: $0.trackId) }
                
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
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        try await dbQueue.write { db in
            // Clear existing collections
            try CollectionRecord.deleteAll(db)
            try CollectionTrackRecord.deleteAll(db)
            
            // Insert all collections
            for collection in collections {
                let collectionRecord = CollectionRecord(from: collection)
                try collectionRecord.insert(db)
                
                // Insert track associations
                for (index, trackID) in collection.trackIDs.enumerated() {
                    let trackRecord = CollectionTrackRecord(
                        collectionId: collection.id.uuidString,
                        trackId: trackID.uuidString,
                        position: index
                    )
                    try trackRecord.insert(db)
                }
            }
        }
    }
}

// MARK: - Database Errors

enum DatabaseError: Error, LocalizedError {
    case notOpen
    case openFailed(message: String)
    
    var errorDescription: String? {
        switch self {
        case .notOpen:
            return "Database is not open"
        case .openFailed(let message):
            return "Failed to open database: \(message)"
        }
    }
}
