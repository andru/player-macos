import Foundation
import GRDB

// MARK: - GRDB Record for Artist

struct ArtistRecord: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var name: String
    var sortName: String?
    var createdAt: Date
    var updatedAt: Date
    
    static let databaseTableName = "artists"
    
    static let releaseGroups = hasMany(ReleaseGroupRecord.self, key: "primaryArtist")
    static let workArtists = hasMany(WorkArtistRecord.self)
    static let recordingArtists = hasMany(RecordingArtistRecord.self)
    
    init(from artist: Artist) {
        self.id = artist.id == 0 ? nil : artist.id
        self.name = artist.name
        self.sortName = artist.sortName
        self.createdAt = artist.createdAt
        self.updatedAt = artist.updatedAt
    }
    
    init(id: Int64? = nil, name: String, sortName: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.sortName = sortName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    func toArtist() -> Artist {
        Artist(
            id: id ?? 0,
            name: name,
            sortName: sortName,
            createdAt: createdAt,
            updatedAt: updatedAt,
            albums: []
        )
    }
}

// MARK: - GRDB Record for Work

struct WorkRecord: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var title: String
    var createdAt: Date
    var updatedAt: Date
    
    static let databaseTableName = "works"
    
    static let workArtists = hasMany(WorkArtistRecord.self)
    static let recordingWorks = hasMany(RecordingWorkRecord.self)
    
    init(from work: Work) {
        self.id = work.id == 0 ? nil : work.id
        self.title = work.title
        self.createdAt = work.createdAt
        self.updatedAt = work.updatedAt
    }
    
    init(id: Int64? = nil, title: String, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    func toWork(artists: [Artist] = [], recordings: [Recording] = []) -> Work {
        Work(
            id: id ?? 0,
            title: title,
            createdAt: createdAt,
            updatedAt: updatedAt,
            artists: artists,
            recordings: recordings
        )
    }
}

// MARK: - GRDB Record for Recording

struct RecordingRecord: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var title: String
    var duration: Double?
    var createdAt: Date
    var updatedAt: Date
    
    static let databaseTableName = "recordings"
    
    static let recordingWorks = hasMany(RecordingWorkRecord.self)
    static let recordingArtists = hasMany(RecordingArtistRecord.self)
    static let recordingDigitalFiles = hasMany(RecordingDigitalFileRecord.self)
    static let tracks = hasMany(TrackRecord.self)
    
    init(from recording: Recording) {
        self.id = recording.id == 0 ? nil : recording.id
        self.title = recording.title
        self.duration = recording.duration
        self.createdAt = recording.createdAt
        self.updatedAt = recording.updatedAt
    }
    
    init(id: Int64? = nil, title: String, duration: Double? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.duration = duration
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    func toRecording(works: [Work] = [], artists: [Artist] = [], digitalFiles: [DigitalFile] = [], tracks: [Track] = []) -> Recording {
        Recording(
            id: id ?? 0,
            title: title,
            duration: duration,
            createdAt: createdAt,
            updatedAt: updatedAt,
            works: works,
            artists: artists,
            digitalFiles: digitalFiles,
            tracks: tracks
        )
    }
}

// MARK: - GRDB Record for Label

struct LabelRecord: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var name: String
    var sortName: String?
    var createdAt: Date
    var updatedAt: Date
    
    static let databaseTableName = "labels"
    
    static let releaseLabels = hasMany(ReleaseLabelRecord.self)
    
    init(from label: Label) {
        self.id = label.id == 0 ? nil : label.id
        self.name = label.name
        self.sortName = label.sortName
        self.createdAt = label.createdAt
        self.updatedAt = label.updatedAt
    }
    
    init(id: Int64? = nil, name: String, sortName: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.sortName = sortName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    func toLabel(releases: [Release] = []) -> Label {
        Label(
            id: id ?? 0,
            name: name,
            sortName: sortName,
            createdAt: createdAt,
            updatedAt: updatedAt,
            releases: releases
        )
    }
}

// MARK: - GRDB Record for ReleaseGroup

struct ReleaseGroupRecord: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var title: String
    var primaryArtistId: Int64?
    var isCompilation: Bool
    var createdAt: Date
    var updatedAt: Date
    
    static let databaseTableName = "release_groups"
    
    static let primaryArtist = belongsTo(ArtistRecord.self, key: "primaryArtist")
    static let releases = hasMany(ReleaseRecord.self)
    
    init(from releaseGroup: ReleaseGroup) {
        self.id = releaseGroup.id == 0 ? nil : releaseGroup.id
        self.title = releaseGroup.title
        self.primaryArtistId = releaseGroup.primaryArtistId
        self.isCompilation = releaseGroup.isCompilation
        self.createdAt = releaseGroup.createdAt
        self.updatedAt = releaseGroup.updatedAt
    }
    
    init(id: Int64? = nil, title: String, primaryArtistId: Int64? = nil, isCompilation: Bool = false, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.primaryArtistId = primaryArtistId
        self.isCompilation = isCompilation
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    func toReleaseGroup(releases: [Release] = [], primaryArtist: Artist? = nil) -> ReleaseGroup {
        ReleaseGroup(
            id: id ?? 0,
            title: title,
            primaryArtistId: primaryArtistId,
            isCompilation: isCompilation,
            createdAt: createdAt,
            updatedAt: updatedAt,
            releases: releases,
            primaryArtist: primaryArtist
        )
    }
}

// MARK: - GRDB Record for Release

struct ReleaseRecord: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var releaseGroupId: Int64
    var format: String
    var edition: String?
    var year: Int?
    var country: String?
    var catalogNumber: String?
    var barcode: String?
    var createdAt: Date
    var updatedAt: Date
    
    static let databaseTableName = "releases"
    
    static let releaseGroup = belongsTo(ReleaseGroupRecord.self)
    static let media = hasMany(MediumRecord.self)
    static let releaseLabels = hasMany(ReleaseLabelRecord.self)
    
    init(from release: Release) {
        self.id = release.id == 0 ? nil : release.id
        self.releaseGroupId = release.releaseGroupId
        self.format = release.format.rawValue
        self.edition = release.edition
        self.year = release.year
        self.country = release.country
        self.catalogNumber = release.catalogNumber
        self.barcode = release.barcode
        self.createdAt = release.createdAt
        self.updatedAt = release.updatedAt
    }
    
    init(id: Int64? = nil, releaseGroupId: Int64, format: String = "Digital", edition: String? = nil, year: Int? = nil, country: String? = nil, catalogNumber: String? = nil, barcode: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.releaseGroupId = releaseGroupId
        self.format = format
        self.edition = edition
        self.year = year
        self.country = country
        self.catalogNumber = catalogNumber
        self.barcode = barcode
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    func toRelease(media: [Medium] = [], labels: [Label] = [], releaseGroup: ReleaseGroup? = nil) -> Release {
        Release(
            id: id ?? 0,
            releaseGroupId: releaseGroupId,
            format: ReleaseFormat(rawValue: format) ?? .other,
            edition: edition,
            year: year,
            country: country,
            catalogNumber: catalogNumber,
            barcode: barcode,
            createdAt: createdAt,
            updatedAt: updatedAt,
            media: media,
            labels: labels,
            releaseGroup: releaseGroup
        )
    }
}

// MARK: - GRDB Record for Medium

struct MediumRecord: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var releaseId: Int64
    var position: Int
    var format: String?
    var title: String?
    var createdAt: Date
    var updatedAt: Date
    
    static let databaseTableName = "media"
    
    static let release = belongsTo(ReleaseRecord.self)
    static let tracks = hasMany(TrackRecord.self)
    
    init(from medium: Medium) {
        self.id = medium.id == 0 ? nil : medium.id
        self.releaseId = medium.releaseId
        self.position = medium.position
        self.format = medium.format
        self.title = medium.title
        self.createdAt = medium.createdAt
        self.updatedAt = medium.updatedAt
    }
    
    init(id: Int64? = nil, releaseId: Int64, position: Int = 1, format: String? = nil, title: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.releaseId = releaseId
        self.position = position
        self.format = format
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    func toMedium(tracks: [Track] = [], release: Release? = nil) -> Medium {
        Medium(
            id: id ?? 0,
            releaseId: releaseId,
            position: position,
            format: format,
            title: title,
            createdAt: createdAt,
            updatedAt: updatedAt,
            tracks: tracks,
            release: release
        )
    }
}

// MARK: - GRDB Record for Track

struct TrackRecord: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var mediumId: Int64
    var recordingId: Int64
    var position: Int
    var titleOverride: String?
    var createdAt: Date
    var updatedAt: Date
    
    static let databaseTableName = "tracks"
    
    static let medium = belongsTo(MediumRecord.self)
    static let recording = belongsTo(RecordingRecord.self)
    
    init(from track: Track) {
        self.id = track.id == 0 ? nil : track.id
        self.mediumId = track.mediumId
        self.recordingId = track.recordingId
        self.position = track.position
        self.titleOverride = track.titleOverride
        self.createdAt = track.createdAt
        self.updatedAt = track.updatedAt
    }
    
    init(id: Int64? = nil, mediumId: Int64, recordingId: Int64, position: Int, titleOverride: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.mediumId = mediumId
        self.recordingId = recordingId
        self.position = position
        self.titleOverride = titleOverride
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    func toTrack(recording: Recording? = nil, medium: Medium? = nil) -> Track {
        Track(
            id: id ?? 0,
            mediumId: mediumId,
            recordingId: recordingId,
            position: position,
            titleOverride: titleOverride,
            createdAt: createdAt,
            updatedAt: updatedAt,
            recording: recording,
            medium: medium
        )
    }
}

// MARK: - GRDB Record for DigitalFile

struct DigitalFileRecord: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var fileURL: String
    var bookmarkData: Data?
    var fileHash: String?
    var fileSize: Int64?
    var addedAt: Date
    var lastScannedAt: Date?
    var metadataJSON: String?
    var artworkData: Data?
    
    static let databaseTableName = "digital_files"
    
    static let recordingDigitalFiles = hasMany(RecordingDigitalFileRecord.self)
    
    init(from digitalFile: DigitalFile) {
        self.id = digitalFile.id == 0 ? nil : digitalFile.id
        self.fileURL = digitalFile.fileURL.path
        self.bookmarkData = digitalFile.bookmarkData
        self.fileHash = digitalFile.fileHash
        self.fileSize = digitalFile.fileSize
        self.addedAt = digitalFile.addedAt
        self.lastScannedAt = digitalFile.lastScannedAt
        self.metadataJSON = digitalFile.metadataJSON
        self.artworkData = digitalFile.artworkData
    }
    
    init(id: Int64? = nil, fileURL: String, bookmarkData: Data? = nil, fileHash: String? = nil, fileSize: Int64? = nil, addedAt: Date = Date(), lastScannedAt: Date? = nil, metadataJSON: String? = nil, artworkData: Data? = nil) {
        self.id = id
        self.fileURL = fileURL
        self.bookmarkData = bookmarkData
        self.fileHash = fileHash
        self.fileSize = fileSize
        self.addedAt = addedAt
        self.lastScannedAt = lastScannedAt
        self.metadataJSON = metadataJSON
        self.artworkData = artworkData
    }
    
    func toDigitalFile(recordings: [Recording] = []) -> DigitalFile {
        DigitalFile(
            id: id ?? 0,
            fileURL: URL(fileURLWithPath: fileURL),
            bookmarkData: bookmarkData,
            fileHash: fileHash,
            fileSize: fileSize,
            addedAt: addedAt,
            lastScannedAt: lastScannedAt,
            metadataJSON: metadataJSON,
            artworkData: artworkData,
            recordings: recordings
        )
    }
}

// MARK: - Join Table Records

struct WorkArtistRecord: Codable, FetchableRecord, PersistableRecord {
    var workId: Int64
    var artistId: Int64
    var role: String?
    
    static let databaseTableName = "work_artist"
    
    static let work = belongsTo(WorkRecord.self)
    static let artist = belongsTo(ArtistRecord.self)
    
    enum Columns {
        static let workId = Column(CodingKeys.workId)
        static let artistId = Column(CodingKeys.artistId)
        static let role = Column(CodingKeys.role)
    }
}

struct RecordingWorkRecord: Codable, FetchableRecord, PersistableRecord {
    var recordingId: Int64
    var workId: Int64
    
    static let databaseTableName = "recording_work"
    
    static let recording = belongsTo(RecordingRecord.self)
    static let work = belongsTo(WorkRecord.self)
    
    enum Columns {
        static let recordingId = Column(CodingKeys.recordingId)
        static let workId = Column(CodingKeys.workId)
    }
}

struct RecordingArtistRecord: Codable, FetchableRecord, PersistableRecord {
    var recordingId: Int64
    var artistId: Int64
    var role: String?
    
    static let databaseTableName = "recording_artist"
    
    static let recording = belongsTo(RecordingRecord.self)
    static let artist = belongsTo(ArtistRecord.self)
    
    enum Columns {
        static let recordingId = Column(CodingKeys.recordingId)
        static let artistId = Column(CodingKeys.artistId)
        static let role = Column(CodingKeys.role)
    }
}

struct ReleaseLabelRecord: Codable, FetchableRecord, PersistableRecord {
    var releaseId: Int64
    var labelId: Int64
    var catalogNumber: String?
    
    static let databaseTableName = "release_label"
    
    static let release = belongsTo(ReleaseRecord.self)
    static let label = belongsTo(LabelRecord.self)
    
    enum Columns {
        static let releaseId = Column(CodingKeys.releaseId)
        static let labelId = Column(CodingKeys.labelId)
        static let catalogNumber = Column(CodingKeys.catalogNumber)
    }
}

struct RecordingDigitalFileRecord: Codable, FetchableRecord, PersistableRecord {
    var recordingId: Int64
    var digitalFileId: Int64
    
    static let databaseTableName = "recording_digital_file"
    
    static let recording = belongsTo(RecordingRecord.self)
    static let digitalFile = belongsTo(DigitalFileRecord.self)
    
    enum Columns {
        static let recordingId = Column(CodingKeys.recordingId)
        static let digitalFileId = Column(CodingKeys.digitalFileId)
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
