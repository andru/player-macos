import Foundation

/// Represents tags read from an audio file at import time
/// This is a snapshot of the file's metadata at the time of the last scan
struct LocalTrackTags: Identifiable, Sendable {
    let id: Int64
    let localTrackId: Int64
    
    // Tag fields
    let title: String?
    let artist: String?
    let album: String?
    let albumArtist: String?
    let composer: String?
    let trackNumber: Int?
    let discNumber: Int?
    let year: Int?
    let genre: String?
    let isCompilation: Bool
    
    // MusicBrainz IDs present in tags (if any)
    let mbidRecording: String?
    let mbidRelease: String?
    let mbidReleaseGroup: String?
    let mbidArtist: String?
    let mbidWork: String?
    
    // Metadata
    let scannedAt: Date
    let createdAt: Date
    let updatedAt: Date
    
    init(
        id: Int64 = 0,
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
}
