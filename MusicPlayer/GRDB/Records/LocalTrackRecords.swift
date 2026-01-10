import GRDB
import Foundation

// MARK: - LocalTrack Record

struct LocalTrackRecord: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var fileURL: String
    var bookmarkData: Data?
    var contentHash: String
    var fileSize: Int64?
    var mtime: Date?
    var duration: TimeInterval?
    var createdAt: Date
    var updatedAt: Date
    
    static let databaseTableName = "local_tracks"
    
    func toLocalTrack() -> LocalTrack {
        LocalTrack(
            id: id ?? 0,
            fileURL: fileURL,
            bookmarkData: bookmarkData,
            contentHash: contentHash,
            fileSize: fileSize,
            mtime: mtime,
            duration: duration,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    static func from(_ localTrack: LocalTrack) -> LocalTrackRecord {
        LocalTrackRecord(
            id: localTrack.id == 0 ? nil : localTrack.id,
            fileURL: localTrack.fileURL,
            bookmarkData: localTrack.bookmarkData,
            contentHash: localTrack.contentHash,
            fileSize: localTrack.fileSize,
            mtime: localTrack.mtime,
            duration: localTrack.duration,
            createdAt: localTrack.createdAt,
            updatedAt: localTrack.updatedAt
        )
    }
}

// MARK: - LocalTrackTags Record

struct LocalTrackTagsRecord: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var localTrackId: Int64
    var title: String?
    var artist: String?
    var album: String?
    var albumArtist: String?
    var composer: String?
    var trackNumber: Int?
    var discNumber: Int?
    var year: Int?
    var isCompilation: Bool
    var genre: String?
    var recordingMBID: String?
    var releaseMBID: String?
    var releaseGroupMBID: String?
    var artistMBID: String?
    var workMBID: String?
    var createdAt: Date
    var updatedAt: Date
    
    static let databaseTableName = "local_track_tags"
    
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
            isCompilation: isCompilation,
            genre: genre,
            recordingMBID: recordingMBID,
            releaseMBID: releaseMBID,
            releaseGroupMBID: releaseGroupMBID,
            artistMBID: artistMBID,
            workMBID: workMBID,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    static func from(_ tags: LocalTrackTags) -> LocalTrackTagsRecord {
        LocalTrackTagsRecord(
            id: tags.id == 0 ? nil : tags.id,
            localTrackId: tags.localTrackId,
            title: tags.title,
            artist: tags.artist,
            album: tags.album,
            albumArtist: tags.albumArtist,
            composer: tags.composer,
            trackNumber: tags.trackNumber,
            discNumber: tags.discNumber,
            year: tags.year,
            isCompilation: tags.isCompilation,
            genre: tags.genre,
            recordingMBID: tags.recordingMBID,
            releaseMBID: tags.releaseMBID,
            releaseGroupMBID: tags.releaseGroupMBID,
            artistMBID: tags.artistMBID,
            workMBID: tags.workMBID,
            createdAt: tags.createdAt,
            updatedAt: tags.updatedAt
        )
    }
}

// MARK: - LibraryTrack Record

struct LibraryTrackRecord: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var localTrackId: Int64
    var localTrackTagsId: Int64
    var createdAt: Date
    var updatedAt: Date
    
    static let databaseTableName = "library_tracks"
    
    func toLibraryTrack() -> LibraryTrack {
        LibraryTrack(
            id: id ?? 0,
            localTrackId: localTrackId,
            localTrackTagsId: localTrackTagsId,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    static func from(_ libraryTrack: LibraryTrack) -> LibraryTrackRecord {
        LibraryTrackRecord(
            id: libraryTrack.id == 0 ? nil : libraryTrack.id,
            localTrackId: libraryTrack.localTrackId,
            localTrackTagsId: libraryTrack.localTrackTagsId,
            createdAt: libraryTrack.createdAt,
            updatedAt: libraryTrack.updatedAt
        )
    }
}

// MARK: - TrackMatch Record

struct TrackMatchRecord: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var libraryTrackId: Int64
    var recordingId: Int64
    var confidence: Double
    var matchedAt: Date
    var createdAt: Date
    var updatedAt: Date
    
    static let databaseTableName = "track_matches"
    
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
    
    static func from(_ trackMatch: TrackMatch) -> TrackMatchRecord {
        TrackMatchRecord(
            id: trackMatch.id == 0 ? nil : trackMatch.id,
            libraryTrackId: trackMatch.libraryTrackId,
            recordingId: trackMatch.recordingId,
            confidence: trackMatch.confidence,
            matchedAt: trackMatch.matchedAt,
            createdAt: trackMatch.createdAt,
            updatedAt: trackMatch.updatedAt
        )
    }
}
