import Foundation
import AppKit
import AVFoundation
import ImageIO
import CryptoKit

// MARK: - macOS-specific Track extensions

extension Track {
    /// Get the artwork as an NSImage (macOS only)
    var artwork: NSImage? {
        guard let artworkData = artworkData else { return nil }
        return NSImage(data: artworkData)
    }
}

// MARK: - Artwork extraction helper (macOS only)
extension Track {
    // Cache directory for artwork thumbnails
    private static var artworkCacheDirectory: URL {
        let fm = FileManager.default
        let caches = fm.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return caches.appendingPathComponent("Vibez/ArtworkCache", isDirectory: true)
    }

    // Generate a stable cache key for a file URL and pixel size (includes modification date to invalidate on file change)
    private static func cacheKey(for fileURL: URL, maxPixel: Int) -> String {
        let path = fileURL.path
        let modDate = (try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate)?.timeIntervalSince1970 ?? 0
        let input = "\(path)-\(modDate)-\(maxPixel)"
        let hash = SHA256.hash(data: Data(input.utf8))
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    private static func cacheFileURL(for fileURL: URL, maxPixel: Int) -> URL {
        let dir = artworkCacheDirectory
        return dir.appendingPathComponent("\(cacheKey(for: fileURL, maxPixel: maxPixel)).jpg")
    }

    private static func ensureCacheDirectoryExists() throws {
        let dir = artworkCacheDirectory
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
    }

    private static func cachedThumbnailData(for fileURL: URL, maxPixel: Int) -> Data? {
        let url = cacheFileURL(for: fileURL, maxPixel: maxPixel)
        return try? Data(contentsOf: url)
    }

    private static func saveThumbnailToCache(_ data: Data, for fileURL: URL, maxPixel: Int) {
        do {
            try ensureCacheDirectoryExists()
            let url = cacheFileURL(for: fileURL, maxPixel: maxPixel)
            try data.write(to: url, options: .atomic)
        } catch {
            // Best-effort cache; ignore failures silently
        }
    }

    /// Extract artwork image data from the file's metadata.
    /// - Parameters:
    ///   - fileURL: URL to the audio file.
    ///   - maxPixelDimension: Maximum pixel size for thumbnailing (preserves aspect ratio).
    /// - Returns: JPEG Data of the artwork thumbnail, or nil if none found.
    static func extractArtworkData(from fileURL: URL, maxPixelDimension: Int = 1024) async throws -> Data? {
        // Check cache first
        if let cached = cachedThumbnailData(for: fileURL, maxPixel: maxPixelDimension) {
            return cached
        }

        let asset = AVURLAsset(url: fileURL)

        // Helper to convert raw image data to a thumbnail JPEG Data
        func thumbnailJPEGData(from rawData: Data, maxPixel: Int) -> Data? {
            guard let source = CGImageSourceCreateWithData(rawData as CFData, nil) else { return nil }
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: maxPixel,
                kCGImageSourceCreateThumbnailWithTransform: true
            ]
            guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
            let rep = NSBitmapImageRep(cgImage: cgImage)
            let jpegData = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.8])
            return jpegData
        }

        // macOS 13+ only: use async AVAsset metadata loaders
        let commonItems: [AVMetadataItem] = try await asset.load(.commonMetadata)
        let formats: [AVMetadataFormat] = try await asset.load(.availableMetadataFormats)

        var items = commonItems
        for format in formats {
            let formatItems: [AVMetadataItem] = try await asset.loadMetadata(for: format)
            items.append(contentsOf: formatItems)
        }

        // Inspect metadata items using typed async loaders
        for item in items {
            let value = try? await item.load(.dataValue)
            if let data = value {
                if let thumb = thumbnailJPEGData(from: data, maxPixel: maxPixelDimension) {
                    saveThumbnailToCache(thumb, for: fileURL, maxPixel: maxPixelDimension)
                    return thumb
                }
                if NSImage(data: data) != nil {
                    saveThumbnailToCache(data, for: fileURL, maxPixel: maxPixelDimension)
                    return data
                }
            }
        }

        return nil
    }

    /// Convenience mutating method: attempt to populate `artworkData` from the track's `fileURL` metadata.
    /// This method does nothing if `artworkData` is already present.
    mutating func loadArtworkFromMetadataIfNeeded(maxPixelDimension: Int = 1024) async {
        if artworkData != nil { return }
        do {
            if let data = try await Track.extractArtworkData(from: fileURL, maxPixelDimension: maxPixelDimension) {
                // Assign the thumbnail data
                self.artworkData = data
            }
        } catch {
            // Ignore errors for now; failure to extract artwork is non-fatal
            // In a larger app you might want to log this.
        }
    }
}
