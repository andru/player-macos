import Foundation
import GRDB

// MARK: - GRDB Database Manager

/// GRDB-based implementation of all music library repositories
class GRDBRepository: 
    ArtistRepository,
    WorkRepository,
    RecordingRepository,
    LabelRepository,
    ReleaseGroupRepository,
    AlbumRepository,
    ReleaseRepository,
    MediumRepository,
    TrackRepository,
    DigitalFileRepository,
    CollectionRepository
{
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
            
            return record.toArtist()
        }
    }
    
    func saveArtist(_ artist: Artist) async throws -> Artist {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.write { db in
            var record = ArtistRecord(from: artist)
            try record.save(db)
            return record.toArtist()
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
    
    // MARK: - WorkRepository
    
    func loadWorks() async throws -> [Work] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            let records = try WorkRecord
                .order(Column("title"))
                .fetchAll(db)
            return records.map { $0.toWork() }
        }
    }
    
    func loadWork(id: Int64) async throws -> Work? {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            guard let record = try WorkRecord.fetchOne(db, key: id) else {
                return nil
            }
            return record.toWork()
        }
    }
    
    func saveWork(_ work: Work) async throws -> Work {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.write { db in
            var record = WorkRecord(from: work)
            try record.save(db)
            return record.toWork()
        }
    }
    
    func findWork(title: String, primaryArtistId: Int64) async throws -> Work? {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
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
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        // Try to find existing work
        if let primaryArtistId = artistIds.first,
           let existing = try await findWork(title: title, primaryArtistId: primaryArtistId) {
            return existing
        }
        
        // Create new work
        return try await dbQueue.write { db in
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
    
    // MARK: - RecordingRepository
    
    func loadRecordings() async throws -> [Recording] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            let records = try RecordingRecord
                .order(Column("title"))
                .fetchAll(db)
            return records.map { $0.toRecording() }
        }
    }
    
    func loadRecording(id: Int64) async throws -> Recording? {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            guard let record = try RecordingRecord.fetchOne(db, key: id) else {
                return nil
            }
            return record.toRecording()
        }
    }
    
    func saveRecording(_ recording: Recording) async throws -> Recording {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.write { db in
            var record = RecordingRecord(from: recording)
            try record.save(db)
            return record.toRecording()
        }
    }
    
    func findRecording(title: String, duration: TimeInterval?) async throws -> Recording? {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            var query = RecordingRecord.filter(Column("title") == title)
            
            if let duration = duration {
                // Match within 1 second tolerance
                query = query.filter(
                    Column("duration") >= (duration - 1.0) &&
                    Column("duration") <= (duration + 1.0)
                )
            }
            
            if let record = try query.fetchOne(db) {
                return record.toRecording()
            }
            return nil
        }
    }
    
    func upsertRecording(title: String, duration: TimeInterval?, workIds: [Int64], artistIds: [Int64]) async throws -> Recording {
        if let existing = try await findRecording(title: title, duration: duration) {
            return existing
        }
        
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.write { db in
            var recordingRecord = RecordingRecord(id: nil, title: title, duration: duration)
            try recordingRecord.save(db)
            
            let recordingId = recordingRecord.id!
            
            // Link works
            for workId in workIds {
                try db.execute(
                    sql: "INSERT INTO recording_work (recordingId, workId) VALUES (?, ?)",
                    arguments: [recordingId, workId]
                )
            }
            
            // Link artists
            for artistId in artistIds {
                try db.execute(
                    sql: "INSERT INTO recording_artist (recordingId, artistId) VALUES (?, ?)",
                    arguments: [recordingId, artistId]
                )
            }
            
            return recordingRecord.toRecording()
        }
    }
    
    func linkRecordingToDigitalFile(recordingId: Int64, digitalFileId: Int64) async throws {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        try await dbQueue.write { db in
            try db.execute(
                sql: "INSERT OR IGNORE INTO recording_digital_file (recordingId, digitalFileId) VALUES (?, ?)",
                arguments: [recordingId, digitalFileId]
            )
        }
    }
    
    // MARK: - LabelRepository
    
    func loadLabels() async throws -> [Label] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            let records = try LabelRecord
                .order(Column("name"))
                .fetchAll(db)
            return records.map { $0.toLabel() }
        }
    }
    
    func loadLabel(id: Int64) async throws -> Label? {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            guard let record = try LabelRecord.fetchOne(db, key: id) else {
                return nil
            }
            return record.toLabel()
        }
    }
    
    func saveLabel(_ label: Label) async throws -> Label {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.write { db in
            var record = LabelRecord(from: label)
            try record.save(db)
            return record.toLabel()
        }
    }
    
    func findLabel(byName name: String) async throws -> Label? {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
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
    
    // MARK: - ReleaseGroupRepository
    
    func loadReleaseGroups() async throws -> [ReleaseGroup] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            let records = try ReleaseGroupRecord
                .order(Column("title"))
                .fetchAll(db)
            return records.map { $0.toReleaseGroup() }
        }
    }
    
    func loadReleaseGroups(forArtistId artistId: Int64) async throws -> [ReleaseGroup] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            let records = try ReleaseGroupRecord
                .filter(Column("primaryArtistId") == artistId)
                .order(Column("title"))
                .fetchAll(db)
            return records.map { $0.toReleaseGroup() }
        }
    }
    
    func loadReleaseGroup(id: Int64, includeReleases: Bool) async throws -> ReleaseGroup? {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            guard let record = try ReleaseGroupRecord.fetchOne(db, key: id) else {
                return nil
            }
            
            if includeReleases {
                let releases = try await loadReleases(forReleaseGroupId: id)
                return record.toReleaseGroup(releases: releases)
            }
            
            return record.toReleaseGroup()
        }
    }
    
    func saveReleaseGroup(_ releaseGroup: ReleaseGroup) async throws -> ReleaseGroup {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.write { db in
            var record = ReleaseGroupRecord(from: releaseGroup)
            try record.save(db)
            return record.toReleaseGroup()
        }
    }
    
    func findReleaseGroup(title: String, primaryArtistId: Int64?) async throws -> ReleaseGroup? {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
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
    
    // MARK: - AlbumRepository (UI compatibility layer)
    
    func loadAlbums() async throws -> [Album] {
        let releaseGroups = try await loadReleaseGroups()
        return releaseGroups.map { rg in
            Album(from: rg)
        }
    }
    
    func loadAlbums(forArtistId artistId: Int64) async throws -> [Album] {
        let releaseGroups = try await loadReleaseGroups(forArtistId: artistId)
        return releaseGroups.map { rg in
            Album(from: rg)
        }
    }
    
    func loadAlbum(id: Int64, includeReleases: Bool) async throws -> Album? {
        guard let releaseGroup = try await loadReleaseGroup(id: id, includeReleases: includeReleases) else {
            return nil
        }
        return Album(from: releaseGroup)
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
    
    func loadReleases(forReleaseGroupId releaseGroupId: Int64) async throws -> [Release] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            let records = try ReleaseRecord
                .filter(Column("releaseGroupId") == releaseGroupId)
                .order(Column("format"), Column("year"))
                .fetchAll(db)
            return records.map { $0.toRelease() }
        }
    }
    
    func loadRelease(id: Int64, includeMedia: Bool) async throws -> Release? {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            guard let record = try ReleaseRecord.fetchOne(db, key: id) else {
                return nil
            }
            
            if includeMedia {
                let media = try await loadMedia(forReleaseId: id)
                return record.toRelease(media: media)
            }
            
            return record.toRelease()
        }
    }
    
    func saveRelease(_ release: Release) async throws -> Release {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.write { db in
            var record = ReleaseRecord(from: release)
            try record.save(db)
            return record.toRelease()
        }
    }
    
    func findRelease(releaseGroupId: Int64, format: ReleaseFormat, edition: String?, year: Int?, country: String?) async throws -> Release? {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
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
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
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
    
    // MARK: - MediumRepository
    
    func loadMedia() async throws -> [Medium] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            let records = try MediumRecord.fetchAll(db)
            return records.map { $0.toMedium() }
        }
    }
    
    func loadMedia(forReleaseId releaseId: Int64) async throws -> [Medium] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            let records = try MediumRecord
                .filter(Column("releaseId") == releaseId)
                .order(Column("position"))
                .fetchAll(db)
            return records.map { $0.toMedium() }
        }
    }
    
    func loadMedium(id: Int64) async throws -> Medium? {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            guard let record = try MediumRecord.fetchOne(db, key: id) else {
                return nil
            }
            return record.toMedium()
        }
    }
    
    func saveMedium(_ medium: Medium) async throws -> Medium {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.write { db in
            var record = MediumRecord(from: medium)
            try record.save(db)
            return record.toMedium()
        }
    }
    
    func findMedium(releaseId: Int64, position: Int) async throws -> Medium? {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
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
    
    func loadTracks(forMediumId mediumId: Int64) async throws -> [Track] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            let records = try TrackRecord
                .filter(Column("mediumId") == mediumId)
                .order(Column("position"))
                .fetchAll(db)
            return records.map { $0.toTrack() }
        }
    }
    
    func loadTrack(id: Int64) async throws -> Track? {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            guard let record = try TrackRecord.fetchOne(db, key: id) else {
                return nil
            }
            return record.toTrack()
        }
    }
    
    func saveTrack(_ track: Track) async throws -> Track {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.write { db in
            var record = TrackRecord(from: track)
            try record.save(db)
            return record.toTrack()
        }
    }
    
    func saveTracks(_ tracks: [Track]) async throws {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        try await dbQueue.write { db in
            for track in tracks {
                var record = TrackRecord(from: track)
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
    
    func loadDigitalFiles(forRecordingId recordingId: Int64) async throws -> [DigitalFile] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
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
            var record = DigitalFileRecord(from: digitalFile)
            try record.save(db)
            return record.toDigitalFile()
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
    
    func loadRecordingsWithoutDigitalFiles() async throws -> [Recording] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            let sql = """
                SELECT r.* FROM recordings r
                LEFT JOIN recording_digital_file rdf ON rdf.recordingId = r.id
                WHERE rdf.digitalFileId IS NULL
            """
            let records = try RecordingRecord.fetchAll(db, sql: sql)
            return records.map { $0.toRecording() }
        }
    }
    
    func loadRecordingsWithDigitalFiles() async throws -> [Recording] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        return try await dbQueue.read { db in
            let sql = """
                SELECT DISTINCT r.* FROM recordings r
                INNER JOIN recording_digital_file rdf ON rdf.recordingId = r.id
            """
            let records = try RecordingRecord.fetchAll(db, sql: sql)
            return records.map { $0.toRecording() }
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
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notOpen
        }
        
        try await dbQueue.write { db in
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
