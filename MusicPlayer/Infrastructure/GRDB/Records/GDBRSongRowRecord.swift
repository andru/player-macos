import GRDB
import Foundation

struct GDBRSongRowRecord: FetchableRecord, Decodable {
    let id: Int64
//    let isPlayable: Bool
    let title: String
    let artistName: String
//    let albumArtistName: String
//    let composerName: String
    let albumTitle: String
//    let discNumber: Int
//    let trackNumber: Int?
    let durationMs: Double?
    let fileUrl: URL
    
    func toSongRow() -> SongRow {
        SongRow(
            id: id,
            title: title,
            artistName: artistName,
            albumTitle: albumTitle,
            duration: durationMs,
            fileUrl: fileUrl
//            discNumber: discNumber,
//            trackNumber: trackNumber
        )
    }
}
