import Foundation
import AppKit

// MARK: - macOS-specific Album extensions

extension Album {
    /// Get the artwork as an NSImage (macOS only)
    var artwork: NSImage? {
        // Prefer artworkData if available
        if let artworkData = artworkData {
            return NSImage(data: artworkData)
        }
        // Fall back to first track's artwork
        if let firstTrackArtwork = tracks.first?.artwork {
            return firstTrackArtwork
        }
        return nil
    }
}
