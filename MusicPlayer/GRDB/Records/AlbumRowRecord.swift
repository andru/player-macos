import GRDB

struct AlbumRowRecord: FetchableRecord, Decodable {
    let id: Int64
    let title: String
    let primaryArtistId: Int64?
    let primaryArtistName: String?
    
    func toAlbumRow() -> AlbumRow {
        AlbumRow(
            id: id,
            title: title,
            primaryArtistId: primaryArtistId,
            primaryArtistName: primaryArtistName
        )
    }
}

struct AlbumDetailsRecord: FetchableRecord, Decodable {
    let id: Int64
    let title: String
    let primaryArtistId: Int64?
    let primaryArtistName: String?
    
    func toAlbumDetails() -> AlbumDetails {
        AlbumDetails(
            id: id,
            title: title,
            primaryArtistId: primaryArtistId,
            primaryArtistName: primaryArtistName
        )
    }
}
