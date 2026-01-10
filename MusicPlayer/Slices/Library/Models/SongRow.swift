import Foundation

struct SongRow: Identifiable {
    let id: Int64
    let title: String
    let artistName: String
//    let albumArtistName: String
//    let composerName: String
    let albumTitle: String
//    let discNumber: Int
//    let trackNumber: Int?
    let duration: TimeInterval?
    let fileUrl: URL?
}

struct SongRowFilter: Equatable, Sendable {
    var searchText: String?          // search-as-you-type - match to title, artist name, album name
    var artistIds: [Artist.ID]?      // limit to artists
    var releaseGroupIds: [ReleaseGroup.ID]?
    var recordingIds: [Recording.ID]?
    var hasDigitalFiles: Bool?
    var isCompilation: Bool?
}

enum SongRowSortOption {
    case titleAsc
    case titleDesc
    case artistAsc
    case artistDesc
    case albumAsc
    case albumDesc
    case durationAsc
    case durationDesc
}

