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
    
    static let albums = hasMany(AlbumRecord.self)
    
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
    
    func toArtist(albums: [Album] = []) -> Artist {
        Artist(
            id: id ?? 0,
            name: name,
            sortName: sortName,
            createdAt: createdAt,
            updatedAt: updatedAt,
            albums: albums
        )
    }
}

// MARK: - GRDB Record for Album

struct AlbumRecord: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var artistId: Int64
    var title: String
    var sortTitle: String?
    var albumArtistName: String?
    var composerName: String?
    var isCompilation: Bool
    var createdAt: Date
    var updatedAt: Date
    
    static let databaseTableName = "albums"
    
    static let artist = belongsTo(ArtistRecord.self)
    static let releases = hasMany(ReleaseRecord.self)
    
    init(from album: Album) {
        self.id = album.id == 0 ? nil : album.id
        self.artistId = album.artistId
        self.title = album.title
        self.sortTitle = album.sortTitle
        self.albumArtistName = album.albumArtistName
        self.composerName = album.composerName
        self.isCompilation = album.isCompilation
        self.createdAt = album.createdAt
        self.updatedAt = album.updatedAt
    }
    
    init(id: Int64? = nil, artistId: Int64, title: String, sortTitle: String? = nil, albumArtistName: String? = nil, composerName: String? = nil, isCompilation: Bool = false, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.artistId = artistId
        self.title = title
        self.sortTitle = sortTitle
        self.albumArtistName = albumArtistName
        self.composerName = composerName
        self.isCompilation = isCompilation
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    func toAlbum(releases: [Release] = [], artist: Artist? = nil) -> Album {
        Album(
            id: id ?? 0,
            artistId: artistId,
            title: title,
            sortTitle: sortTitle,
            albumArtistName: albumArtistName,
            composerName: composerName,
            isCompilation: isCompilation,
            createdAt: createdAt,
            updatedAt: updatedAt,
            releases: releases,
            artist: artist
        )
    }
}

// MARK: - GRDB Record for Release

struct ReleaseRecord: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var albumId: Int64
    var format: String
    var edition: String?
    var label: String?
    var year: Int?
    var country: String?
    var catalogNumber: String?
    var barcode: String?
    var discs: Int
    var releaseTitleOverride: String?
    var userNotes: String?
    var isCompilation: Bool
    var createdAt: Date
    var updatedAt: Date
    
    static let databaseTableName = "releases"
    
    static let album = belongsTo(AlbumRecord.self)
    static let tracks = hasMany(TrackRecord.self)
    
    init(from release: Release) {
        self.id = release.id == 0 ? nil : release.id
        self.albumId = release.albumId
        self.format = release.format.rawValue
        self.edition = release.edition
        self.label = release.label
        self.year = release.year
        self.country = release.country
        self.catalogNumber = release.catalogNumber
        self.barcode = release.barcode
        self.discs = release.discs
        self.releaseTitleOverride = release.releaseTitleOverride
        self.userNotes = release.userNotes
        self.isCompilation = release.isCompilation
        self.createdAt = release.createdAt
        self.updatedAt = release.updatedAt
    }
    
    init(id: Int64? = nil, albumId: Int64, format: String = "Digital", edition: String? = nil, label: String? = nil, year: Int? = nil, country: String? = nil, catalogNumber: String? = nil, barcode: String? = nil, discs: Int = 1, releaseTitleOverride: String? = nil, userNotes: String? = nil, isCompilation: Bool = false, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.albumId = albumId
        self.format = format
        self.edition = edition
        self.label = label
        self.year = year
        self.country = country
        self.catalogNumber = catalogNumber
        self.barcode = barcode
        self.discs = discs
        self.releaseTitleOverride = releaseTitleOverride
        self.userNotes = userNotes
        self.isCompilation = isCompilation
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    func toRelease(tracks: [Track] = [], album: Album? = nil) -> Release {
        Release(
            id: id ?? 0,
            albumId: albumId,
            format: ReleaseFormat(rawValue: format) ?? .other,
            edition: edition,
            label: label,
            year: year,
            country: country,
            catalogNumber: catalogNumber,
            barcode: barcode,
            discs: discs,
            releaseTitleOverride: releaseTitleOverride,
            userNotes: userNotes,
            isCompilation: isCompilation,
            createdAt: createdAt,
            updatedAt: updatedAt,
            tracks: tracks,
            album: album
        )
    }
}

// MARK: - GRDB Record for Track

struct TrackRecord: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var releaseId: Int64
    var discNumber: Int
    var trackNumber: Int?
    var title: String
    var duration: Double?
    var artistName: String
    var albumArtistName: String?
    var composerName: String?
    var genre: String?
    var createdAt: Date
    var updatedAt: Date
    
    static let databaseTableName = "tracks"
    
    static let release = belongsTo(ReleaseRecord.self)
    static let digitalFiles = hasMany(DigitalFileRecord.self)
    
    init(from track: Track) {
        self.id = track.id == 0 ? nil : track.id
        self.releaseId = track.releaseId
        self.discNumber = track.discNumber
        self.trackNumber = track.trackNumber
        self.title = track.title
        self.duration = track.duration
        self.artistName = track.artistName
        self.albumArtistName = track.albumArtistName
        self.composerName = track.composerName
        self.genre = track.genre
        self.createdAt = track.createdAt
        self.updatedAt = track.updatedAt
    }
    
    init(id: Int64? = nil, releaseId: Int64, discNumber: Int = 1, trackNumber: Int? = nil, title: String, duration: Double? = nil, artistName: String, albumArtistName: String? = nil, composerName: String? = nil, genre: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.releaseId = releaseId
        self.discNumber = discNumber
        self.trackNumber = trackNumber
        self.title = title
        self.duration = duration
        self.artistName = artistName
        self.albumArtistName = albumArtistName
        self.composerName = composerName
        self.genre = genre
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    func toTrack(digitalFiles: [DigitalFile] = [], release: Release? = nil) -> Track {
        Track(
            id: id ?? 0,
            releaseId: releaseId,
            discNumber: discNumber,
            trackNumber: trackNumber,
            title: title,
            duration: duration,
            artistName: artistName,
            albumArtistName: albumArtistName,
            composerName: composerName,
            genre: genre,
            createdAt: createdAt,
            updatedAt: updatedAt,
            digitalFiles: digitalFiles,
            release: release
        )
    }
}

// MARK: - GRDB Record for DigitalFile

struct DigitalFileRecord: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var trackId: Int64
    var fileURL: String
    var bookmarkData: Data?
    var fileHash: String?
    var fileSize: Int64?
    var addedAt: Date
    var lastScannedAt: Date?
    var metadataJSON: String?
    var artworkData: Data?
    
    static let databaseTableName = "digital_files"
    
    static let track = belongsTo(TrackRecord.self)
    
    init(from digitalFile: DigitalFile) {
        self.id = digitalFile.id == 0 ? nil : digitalFile.id
        self.trackId = digitalFile.trackId
        self.fileURL = digitalFile.fileURL.path
        self.bookmarkData = digitalFile.bookmarkData
        self.fileHash = digitalFile.fileHash
        self.fileSize = digitalFile.fileSize
        self.addedAt = digitalFile.addedAt
        self.lastScannedAt = digitalFile.lastScannedAt
        self.metadataJSON = digitalFile.metadataJSON
        self.artworkData = digitalFile.artworkData
    }
    
    init(id: Int64? = nil, trackId: Int64, fileURL: String, bookmarkData: Data? = nil, fileHash: String? = nil, fileSize: Int64? = nil, addedAt: Date = Date(), lastScannedAt: Date? = nil, metadataJSON: String? = nil, artworkData: Data? = nil) {
        self.id = id
        self.trackId = trackId
        self.fileURL = fileURL
        self.bookmarkData = bookmarkData
        self.fileHash = fileHash
        self.fileSize = fileSize
        self.addedAt = addedAt
        self.lastScannedAt = lastScannedAt
        self.metadataJSON = metadataJSON
        self.artworkData = artworkData
    }
    
    func toDigitalFile(track: Track? = nil) -> DigitalFile {
        DigitalFile(
            id: id ?? 0,
            trackId: trackId,
            fileURL: URL(fileURLWithPath: fileURL),
            bookmarkData: bookmarkData,
            fileHash: fileHash,
            fileSize: fileSize,
            addedAt: addedAt,
            lastScannedAt: lastScannedAt,
            metadataJSON: metadataJSON,
            artworkData: artworkData,
            track: track
        )
    }
}
