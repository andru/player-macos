import Foundation

struct SongRow: Identifiable {
    let id: Int64  // library_track.id
    let title: String
    let artistName: String
    let albumTitle: String
    let trackNumber: Int?
    let discNumber: Int?
    let duration: TimeInterval?
    let fileUrl: URL?
}

struct SongRowFilter: Equatable, Sendable {
    var searchText: String?          // search-as-you-type - match to title, artist name, album name
    var artistNames: [String]?       // limit to specific artists
    var albumTitles: [String]?       // limit to specific albums
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

