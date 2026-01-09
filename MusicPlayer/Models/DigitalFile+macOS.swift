import Foundation
import AppKit

// MARK: - macOS-specific Track extensions

extension DigitalFile {
    // Track no longer has artwork data directly - it's on DigitalFile
    // Use track.digitalFiles.first?.artworkData to access artwork
    var artwork: NSImage? {
//        guard let artworkData = digitalFiles.first?.artworkData else { return nil }
//        return NSImage(data: artworkData)
        return nil
    }
}
