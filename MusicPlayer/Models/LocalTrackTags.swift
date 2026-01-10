import Foundation

/// Represents tags read from an audio file at import time
/// Current snapshot only - no history tracking
struct LocalTrackTags: Identifiable, Hashable {
    let id: Int64
    var localTrackId: Int64  // FK to local_track
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
    
    // MusicBrainz IDs if present in tags
    var recordingMBID: String?
    var releaseMBID: String?
    var releaseGroupMBID: String?
    var artistMBID: String?
    var workMBID: String?
    
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: Int64,
        localTrackId: Int64,
        title: String? = nil,
        artist: String? = nil,
        album: String? = nil,
        albumArtist: String? = nil,
        composer: String? = nil,
        trackNumber: Int? = nil,
        discNumber: Int? = nil,
        year: Int? = nil,
        isCompilation: Bool = false,
        genre: String? = nil,
        recordingMBID: String? = nil,
        releaseMBID: String? = nil,
        releaseGroupMBID: String? = nil,
        artistMBID: String? = nil,
        workMBID: String? = nil,
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
        self.isCompilation = isCompilation
        self.genre = genre
        self.recordingMBID = recordingMBID
        self.releaseMBID = releaseMBID
        self.releaseGroupMBID = releaseGroupMBID
        self.artistMBID = artistMBID
        self.workMBID = workMBID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id, localTrackId, title, artist, album, albumArtist, composer
        case trackNumber, discNumber, year, isCompilation, genre
        case recordingMBID, releaseMBID, releaseGroupMBID, artistMBID, workMBID
        case createdAt, updatedAt
    }
}
