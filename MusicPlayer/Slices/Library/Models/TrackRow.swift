import Foundation

struct TrackRow: Identifiable {
    let id: Int64
    let isPlayable: Bool
    let title: String
    let artistName: String
    let albumArtistName: String
    let composerName: String
    let albumTitle: String
    let discNumber: Int
    let trackNumber: Int?
    let duration: TimeInterval?
    
    init (id: Int64,
        isPlayable: Bool,
        title: String,
        artistName: String,
        albumArtistName: String,
        composerName: String,
        albumTitle: String,
        discNumber: Int,
        trackNumber: Int? = nil,
        duration: TimeInterval? = nil) {
        
        self.id = id
        self.isPlayable = isPlayable
        self.title = title
        self.artistName = artistName
        self.albumArtistName = albumArtistName
        self.composerName = composerName
        self.albumTitle = albumTitle
        self.discNumber = discNumber
        self.trackNumber = trackNumber
        self.duration = duration
        
    }
}

struct TrackRowFilter: Equatable, Sendable {
    var searchText: String?          // search-as-you-type - match to title, artist name, album name
    var artistIds: [Artist.ID]?      // limit to artists
    var releaseGroupIds: [ReleaseGroup.ID]?
    var recordingIds: [Recording.ID]?
    var hasDigitalFiles: Bool?
    var isCompilation: Bool?
}

enum TrackRowSortOption {
    case titleAsc
    case titleDesc
    case artistAsc
    case artistDesc
    case albumAsc
    case albumDesc
    case durationAsc
    case durationDesc
}

