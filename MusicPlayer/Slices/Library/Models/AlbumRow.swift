import Foundation
import AppKit

struct AlbumRow: Identifiable {
    let id: Int64
    let title: String
    let primaryArtistId: Int64?
    let primaryArtistName: String?
    let artwork: NSImage?
}
