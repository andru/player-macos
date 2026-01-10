import Foundation

struct PlayerMedia {
    let id: Int64
    var title: String
    var artist: String
    var album: String
    var albumArtist: String?
    var duration: TimeInterval
    var fileURL: URL?
    var artworkURL: URL?
    var artworkData: Data?
    var genre: String?
    var year: Int?
    var trackNumber: Int?

    // Internal reference to the new track ID
    var trackId: Int64 { id }
    // DigitalFile may be nil for legacy or missing files
    var digitalFile: DigitalFile?


    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
