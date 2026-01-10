import Foundation
import GRDB

// MARK: - GRDB Record for LocalTrack

struct LocalTrackRecord: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var contentHash: String
    var fileURL: String
    var bookmarkData: Data?
    var fileSize: Int64?
    var modifiedAt: Date?
    var duration: Double?
    var addedAt: Date
    var lastScannedAt: Date
    var createdAt: Date
    var updatedAt: Date
    
    static let databaseTableName = "local_track"
    
    static let localTrackTags = hasMany(LocalTrackTagsRecord.self)
    static let libraryTracks = hasMany(LibraryTrackRecord.self)
    
    init(from localTrack: LocalTrack) {
        self.id = localTrack.id == 0 ? nil : localTrack.id
        self.contentHash = localTrack.contentHash
        self.fileURL = localTrack.fileURL
        self.bookmarkData = localTrack.bookmarkData
        self.fileSize = localTrack.fileSize
        self.modifiedAt = localTrack.modifiedAt
        self.duration = localTrack.duration
        self.addedAt = localTrack.addedAt
        self.lastScannedAt = localTrack.lastScannedAt
        self.createdAt = localTrack.createdAt
        self.updatedAt = localTrack.updatedAt
    }
    
    init(
        id: Int64? = nil,
        contentHash: String,
        fileURL: String,
        bookmarkData: Data? = nil,
        fileSize: Int64? = nil,
        modifiedAt: Date? = nil,
        duration: Double? = nil,
        addedAt: Date = Date(),
        lastScannedAt: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.contentHash = contentHash
        self.fileURL = fileURL
        self.bookmarkData = bookmarkData
        self.fileSize = fileSize
        self.modifiedAt = modifiedAt
        self.duration = duration
        self.addedAt = addedAt
        self.lastScannedAt = lastScannedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    func toLocalTrack() -> LocalTrack {
        LocalTrack(
            id: id ?? 0,
            contentHash: contentHash,
            fileURL: fileURL,
            bookmarkData: bookmarkData,
            fileSize: fileSize,
            modifiedAt: modifiedAt,
            duration: duration,
            addedAt: addedAt,
            lastScannedAt: lastScannedAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

// MARK: - GRDB Record for LocalTrackTags

struct LocalTrackTagsRecord: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var localTrackId: Int64
    
    // Tag fields
    var title: String?
    var artist: String?
    var album: String?
    var albumArtist: String?
    var composer: String?
    var trackNumber: Int?
    var discNumber: Int?
    var year: Int?
    var genre: String?
    var isCompilation: Bool
    
    // MusicBrainz IDs
    var mbidRecording: String?
    var mbidRelease: String?
    var mbidReleaseGroup: String?
    var mbidArtist: String?
    var mbidWork: String?
    
    // Metadata
    var scannedAt: Date
    var createdAt: Date
    var updatedAt: Date
    
    static let databaseTableName = "local_track_tags"
    
    static let localTrack = belongsTo(LocalTrackRecord.self)
    static let libraryTracks = hasMany(LibraryTrackRecord.self)
    
    init(from tags: LocalTrackTags) {
        self.id = tags.id == 0 ? nil : tags.id
        self.localTrackId = tags.localTrackId
        self.title = tags.title
        self.artist = tags.artist
        self.album = tags.album
        self.albumArtist = tags.albumArtist
        self.composer = tags.composer
        self.trackNumber = tags.trackNumber
        self.discNumber = tags.discNumber
        self.year = tags.year
        self.genre = tags.genre
        self.isCompilation = tags.isCompilation
        self.mbidRecording = tags.mbidRecording
        self.mbidRelease = tags.mbidRelease
        self.mbidReleaseGroup = tags.mbidReleaseGroup
        self.mbidArtist = tags.mbidArtist
        self.mbidWork = tags.mbidWork
        self.scannedAt = tags.scannedAt
        self.createdAt = tags.createdAt
        self.updatedAt = tags.updatedAt
    }
    
    init(
        id: Int64? = nil,
        localTrackId: Int64,
        title: String? = nil,
        artist: String? = nil,
        album: String? = nil,
        albumArtist: String? = nil,
        composer: String? = nil,
        trackNumber: Int? = nil,
        discNumber: Int? = nil,
        year: Int? = nil,
        genre: String? = nil,
        isCompilation: Bool = false,
        mbidRecording: String? = nil,
        mbidRelease: String? = nil,
        mbidReleaseGroup: String? = nil,
        mbidArtist: String? = nil,
        mbidWork: String? = nil,
        scannedAt: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.localTrackId = localTrackId
        self.title = title
        self.artist = artist
        self.album = album
        self.albumArtist = albumArtist
        self.composer = composer
        self.trackNumber = trackNumber
        self.discNumber = discNumber
        self.year = year
        self.genre = genre
        self.isCompilation = isCompilation
        self.mbidRecording = mbidRecording
        self.mbidRelease = mbidRelease
        self.mbidReleaseGroup = mbidReleaseGroup
        self.mbidArtist = mbidArtist
        self.mbidWork = mbidWork
        self.scannedAt = scannedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    func toLocalTrackTags() -> LocalTrackTags {
        LocalTrackTags(
            id: id ?? 0,
            localTrackId: localTrackId,
            title: title,
            artist: artist,
            album: album,
            albumArtist: albumArtist,
            composer: composer,
            trackNumber: trackNumber,
            discNumber: discNumber,
            year: year,
            genre: genre,
            isCompilation: isCompilation,
            mbidRecording: mbidRecording,
            mbidRelease: mbidRelease,
            mbidReleaseGroup: mbidReleaseGroup,
            mbidArtist: mbidArtist,
            mbidWork: mbidWork,
            scannedAt: scannedAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

// MARK: - GRDB Record for LibraryTrack

struct LibraryTrackRecord: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var localTrackId: Int64
    var localTrackTagsId: Int64
    var addedAt: Date
    var createdAt: Date
    var updatedAt: Date
    
    static let databaseTableName = "library_track"
    
    static let localTrack = belongsTo(LocalTrackRecord.self)
    static let localTrackTags = belongsTo(LocalTrackTagsRecord.self)
    static let trackMatches = hasMany(TrackMatchRecord.self)
    
    init(from libraryTrack: LibraryTrack) {
        self.id = libraryTrack.id == 0 ? nil : libraryTrack.id
        self.localTrackId = libraryTrack.localTrackId
        self.localTrackTagsId = libraryTrack.localTrackTagsId
        self.addedAt = libraryTrack.addedAt
        self.createdAt = libraryTrack.createdAt
        self.updatedAt = libraryTrack.updatedAt
    }
    
    init(
        id: Int64? = nil,
        localTrackId: Int64,
        localTrackTagsId: Int64,
        addedAt: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.localTrackId = localTrackId
        self.localTrackTagsId = localTrackTagsId
        self.addedAt = addedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    func toLibraryTrack() -> LibraryTrack {
        LibraryTrack(
            id: id ?? 0,
            localTrackId: localTrackId,
            localTrackTagsId: localTrackTagsId,
            addedAt: addedAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

// MARK: - GRDB Record for TrackMatch

struct TrackMatchRecord: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var libraryTrackId: Int64
    var recordingId: Int64
    var confidence: Double
    var matchedAt: Date
    var createdAt: Date
    var updatedAt: Date
    
    static let databaseTableName = "local_track_match"
    
    static let libraryTrack = belongsTo(LibraryTrackRecord.self)
    static let recording = belongsTo(RecordingRecord.self)
    
    init(from trackMatch: TrackMatch) {
        self.id = trackMatch.id == 0 ? nil : trackMatch.id
        self.libraryTrackId = trackMatch.libraryTrackId
        self.recordingId = trackMatch.recordingId
        self.confidence = trackMatch.confidence
        self.matchedAt = trackMatch.matchedAt
        self.createdAt = trackMatch.createdAt
        self.updatedAt = trackMatch.updatedAt
    }
    
    init(
        id: Int64? = nil,
        libraryTrackId: Int64,
        recordingId: Int64,
        confidence: Double = 1.0,
        matchedAt: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.libraryTrackId = libraryTrackId
        self.recordingId = recordingId
        self.confidence = confidence
        self.matchedAt = matchedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    func toTrackMatch() -> TrackMatch {
        TrackMatch(
            id: id ?? 0,
            libraryTrackId: libraryTrackId,
            recordingId: recordingId,
            confidence: confidence,
            matchedAt: matchedAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
