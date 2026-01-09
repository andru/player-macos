import Foundation
import GRDB

// MARK: - GRDB Database Manager

/// GRDB-based implementation of all music library repositories
class GRDBRepository: TrackRepository, CollectionRepository, ArtistRepository, AlbumRepository, ReleaseRepository, DigitalFileRepository {
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
            try await dbQueue.write { db in
                
            }
            try DatabaseMigrations.makeMigrator().migrate(dbQueue)
        } catch {
            throw DatabaseError.openFailed(message: error.localizedDescription)
        }
    }
    
    /// Close the database connection
    func closeDatabase() {
        dbQueue = nil
    }
    
    // MARK: - ArtistRepository
    
    func loadArtists() async throws -> [Artist] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            let records = try ArtistRecord
                .order(Column("name"))
                .fetchAll(db)
            return records.map { $0.toArtist() }
        }
    }
    
    func loadArtist(id: Int64, includeAlbums: Bool) async throws -> Artist? {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            guard let record = try ArtistRecord.fetchOne(db, key: id) else {
                return nil
            }
            
            if includeAlbums {
                let albums = try loadAlbums(forArtistId: id, withDb: db)
                return record.toArtist(albums: albums)
            }
            
            return record.toArtist()
        }
    }
    
    func saveArtist(_ artist: Artist) async throws -> Artist {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.write { db in
            let record = ArtistRecord(from: artist)
            try record.save(db)
            return record.toArtist(albums: artist.albums)
        }
    }
    
    func findArtist(byName name: String) async throws -> Artist? {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            if let record = try ArtistRecord
                .filter(Column("name") == name)
                .fetchOne(db) {
                return record.toArtist()
            }
            return nil
        }
    }
    
    func upsertArtist(name: String, sortName: String?) async throws -> Artist {
        if let existing = try await findArtist(byName: name) {
            return existing
        }
        
        let newArtist = Artist(
            id: 0,
            name: name,
            sortName: sortName,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        return try await saveArtist(newArtist)
    }
    
    // MARK: - AlbumRepository
    
    func loadAlbums() async throws -> [Album] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            let records = try AlbumRecord
                .order(Column("title"))
                .fetchAll(db)
            return records.map { $0.toAlbum() }
        }
    }
    
    func loadAlbums(forArtistId artistId: Int64) async throws -> [Album] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            let records = try AlbumRecord
                .filter(Column("artistId") == artistId)
                .order(Column("title"))
                .fetchAll(db)
            return records.map { $0.toAlbum() }
        }
    }
    
    // for using inside an already running queue
    func loadAlbums(forArtistId artistId: Int64, withDb: Database) throws -> [Album] {
        let records = try AlbumRecord
            .filter(Column("artistId") == artistId)
            .order(Column("title"))
            .fetchAll(withDb)
        return records.map { $0.toAlbum() }
    }
    
    func loadAlbum(id: Int64, includeReleases: Bool) async throws -> Album? {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            guard let record = try AlbumRecord.fetchOne(db, key: id) else {
                return nil
            }
            
            if includeReleases {
                let releases = try loadReleases(forAlbumId: id, withDb: db)
                return record.toAlbum(releases: releases)
            }
            
            return record.toAlbum()
        }
    }
    
    func saveAlbum(_ album: Album) async throws -> Album {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.write { db in
            let record = AlbumRecord(from: album)
            try record.save(db)
            return record.toAlbum(releases: album.releases, artist: album.artist)
        }
    }
    
    func findAlbum(artistId: Int64, title: String) async throws -> Album? {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            if let record = try AlbumRecord
                .filter(Column("artistId") == artistId && Column("title") == title)
                .fetchOne(db) {
                return record.toAlbum()
            }
            return nil
        }
    }
    
    func upsertAlbum(artistId: Int64, title: String, artistName: String, albumArtistName: String?, composerName: String?, isCompilation: Bool) async throws -> Album {
        if let existing = try await findAlbum(artistId: artistId, title: title) {
            // Update fields if they've changed
            var updated = existing
            var needsUpdate = false
            
            if updated.artistName != artistName {
                updated.artistName = artistName
                needsUpdate = true
            }
            
            if updated.albumArtistName != albumArtistName {
                updated.albumArtistName = albumArtistName
                needsUpdate = true
            }
            if updated.composerName != composerName {
                updated.composerName = composerName
                needsUpdate = true
            }
            if updated.isCompilation != isCompilation {
                updated.isCompilation = isCompilation
                needsUpdate = true
            }
            
            if needsUpdate {
                updated.updatedAt = Date()
                return try await saveAlbum(updated)
            }
            
            return existing
        }
        
        let newAlbum = Album(
            id: 0,
            artistId: artistId,
            title: title,
            albumArtistName: albumArtistName,
            composerName: composerName,
            isCompilation: isCompilation,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        return try await saveAlbum(newAlbum)
    }
    
    // MARK: - ReleaseRepository
    
    func loadReleases() async throws -> [Release] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            let records = try ReleaseRecord.fetchAll(db)
            return records.map { $0.toRelease() }
        }
    }
    
    func loadReleases(forAlbumId albumId: Int64) async throws -> [Release] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            try loadReleases(forAlbumId: albumId, withDb: db)
        }
    }
    
    func loadReleases(forAlbumId albumId: Int64, withDb: Database) throws -> [Release] {
        let records = try ReleaseRecord
            .filter(Column("albumId") == albumId)
            .order(Column("format"), Column("year"))
            .fetchAll(withDb)
        return records.map { $0.toRelease() }
    }
    
    func loadRelease(id: Int64, includeTracks: Bool) async throws -> Release? {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            guard let record = try ReleaseRecord.fetchOne(db, key: id) else {
                return nil
            }
            
            if includeTracks {
                let tracks = try loadTracks(forReleaseId: id, orderByDiscAndTrackNumber: true, withDb: db)
                return record.toRelease(tracks: tracks)
            }
            
            return record.toRelease()
        }
    }
    
    func saveRelease(_ release: Release) async throws -> Release {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.write { db in
            let record = ReleaseRecord(from: release)
            try record.save(db)
            return record.toRelease(tracks: release.tracks, album: release.album)
        }
    }
    
    func findRelease(albumId: Int64, format: ReleaseFormat, edition: String?, label: String?, year: Int?, country: String?) async throws -> Release? {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            var query = ReleaseRecord
                .filter(Column("albumId") == albumId && Column("format") == format.rawValue)
            
            // Build query with nullable fields
            if let edition = edition {
                query = query.filter(Column("edition") == edition)
            } else {
                query = query.filter(Column("edition") == nil)
            }
            
            if let label = label {
                query = query.filter(Column("label") == label)
            } else {
                query = query.filter(Column("label") == nil)
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
    
    func upsertRelease(albumId: Int64, format: ReleaseFormat, edition: String?, label: String?, year: Int?, country: String?, catalogNumber: String?, barcode: String?, discs: Int, isCompilation: Bool) async throws -> Release {
        if let existing = try await findRelease(albumId: albumId, format: format, edition: edition, label: label, year: year, country: country) {
            return existing
        }
        
        let newRelease = Release(
            id: 0,
            albumId: albumId,
            format: format,
            edition: edition,
            label: label,
            year: year,
            country: country,
            catalogNumber: catalogNumber,
            barcode: barcode,
            discs: discs,
            isCompilation: isCompilation,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        return try await saveRelease(newRelease)
    }
    
    func getDefaultRelease(forAlbumId albumId: Int64) async throws -> Release? {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            // Prefer Digital format if present
            if let digital = try ReleaseRecord
                .filter(Column("albumId") == albumId && Column("format") == "Digital")
                .fetchOne(db) {
                return digital.toRelease()
            }
            
            // Otherwise return the first release for this album
            if let any = try ReleaseRecord
                .filter(Column("albumId") == albumId)
                .fetchOne(db) {
                return any.toRelease()
            }
            
            return nil
        }
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
    
    func loadTracks(forReleaseId releaseId: Int64, orderByDiscAndTrackNumber: Bool) async throws -> [Track] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            try loadTracks(forReleaseId: releaseId, orderByDiscAndTrackNumber: orderByDiscAndTrackNumber, withDb: db)
        }
    }
    
    func loadTracks(forReleaseId releaseId: Int64, orderByDiscAndTrackNumber: Bool, withDb: Database) throws -> [Track] {
        var query = TrackRecord.filter(Column("releaseId") == releaseId)
        
        if orderByDiscAndTrackNumber {
            query = query.order(Column("discNumber"), Column("trackNumber"))
        }
        
        let records = try query.fetchAll(withDb)
        return records.map { $0.toTrack() }

    }
    
    func loadTrack(id: Int64, includeDigitalFiles: Bool) async throws -> Track? {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            guard let record = try TrackRecord.fetchOne(db, key: id) else {
                return nil
            }
            
            if includeDigitalFiles {
                let digitalFiles = try loadDigitalFiles(forTrackId: id, withDb: db)
                return record.toTrack(digitalFiles: digitalFiles)
            }
            
            return record.toTrack()
        }
    }
    
    func saveTrack(_ track: Track) async throws -> Track {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.write { db in
            let record = TrackRecord(from: track)
            try record.save(db)
            return record.toTrack(digitalFiles: track.digitalFiles, release: track.release)
        }
    }
    
    func saveTracks(_ tracks: [Track]) async throws {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        try await dbQueue.write { db in
            for track in tracks {
                let record = TrackRecord(from: track)
                try record.save(db)
            }
        }
    }
    
    // MARK: - DigitalFileRepository
    
    func loadDigitalFiles() async throws -> [DigitalFile] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            let records = try DigitalFileRecord.fetchAll(db)
            return records.map { $0.toDigitalFile() }
        }
    }
    
    func loadDigitalFiles(forTrackId trackId: Int64) async throws -> [DigitalFile] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            let records = try DigitalFileRecord
                .filter(Column("trackId") == trackId)
                .fetchAll(db)
            return records.map { $0.toDigitalFile() }
        }
    }
    
    func loadDigitalFiles(forTrackId trackId: Int64, withDb: Database) throws -> [DigitalFile] {
            let records = try DigitalFileRecord
                .filter(Column("trackId") == trackId)
                .fetchAll(withDb)
            return records.map { $0.toDigitalFile() }
    }
    
    func loadDigitalFile(id: Int64) async throws -> DigitalFile? {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            guard let record = try DigitalFileRecord.fetchOne(db, key: id) else {
                return nil
            }
            return record.toDigitalFile()
        }
    }
    
    func saveDigitalFile(_ digitalFile: DigitalFile) async throws -> DigitalFile {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.write { db in
            let record = DigitalFileRecord(from: digitalFile)
            try record.save(db)
            return record.toDigitalFile(track: digitalFile.track)
        }
    }
    
    func findDigitalFile(byFileURL fileURL: URL) async throws -> DigitalFile? {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            if let record = try DigitalFileRecord
                .filter(Column("fileURL") == fileURL.path)
                .fetchOne(db) {
                return record.toDigitalFile()
            }
            return nil
        }
    }
    
    func loadTracksWithoutDigitalFiles() async throws -> [Track] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            let sql = """
                SELECT t.* FROM tracks t
                LEFT JOIN digital_files df ON df.trackId = t.id
                WHERE df.id IS NULL
                ORDER BY t.discNumber, t.trackNumber
            """
            let records = try TrackRecord.fetchAll(db, sql: sql)
            return records.map { $0.toTrack() }
        }
    }
    
    func loadTracksWithDigitalFiles() async throws -> [Track] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            let sql = """
                SELECT DISTINCT t.* FROM tracks t
                INNER JOIN digital_files df ON df.trackId = t.id
                ORDER BY t.discNumber, t.trackNumber
            """
            let records = try TrackRecord.fetchAll(db, sql: sql)
            return records.map { $0.toTrack() }
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
                
                // Track IDs are now Int64, need to convert from String if stored as String
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
                        trackId: String(trackID),
                        position: index
                    )
                    try trackRecord.insert(db)
                }
            }
        }
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
