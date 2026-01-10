import Foundation
import AppKit

// MARK: - macOS-specific Album extensions

extension Album {
    /// Get the artwork as an NSImage (macOS only)
    var artwork: NSImage? {
        // Get artwork from first track's first digital file
        for release in releases {
//            for track in release.tracks {
//                if let artworkData = track.digitalFiles.first?.artworkData {
//                    return NSImage(data: artworkData)
//                }
//            }
        }
        return nil
    }
}
