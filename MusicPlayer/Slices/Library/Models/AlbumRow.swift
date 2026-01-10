import Foundation
import AppKit

struct AlbumRow: Identifiable {
    let id: String  // Composite key: album + albumArtist (or compilation marker)
    let title: String
    let albumArtist: String?
    let isCompilation: Bool
    let trackCount: Int
    let artwork: NSImage?
    
    init(id: String, title: String, albumArtist: String?, isCompilation: Bool, trackCount: Int, artwork: NSImage? = nil) {
        self.id = id
        self.title = title
        self.albumArtist = albumArtist
        self.isCompilation = isCompilation
        self.trackCount = trackCount
        self.artwork = artwork
    }
}
