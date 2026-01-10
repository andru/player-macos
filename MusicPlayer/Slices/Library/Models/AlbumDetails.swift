import GRDB

struct AlbumDetails: Identifiable {
    let id: Int64
    let title: String
    let primaryArtistId: Int64?
    let primaryArtistName: String?
}
