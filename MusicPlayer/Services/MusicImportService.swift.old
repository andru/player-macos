import Foundation
@preconcurrency import AVFoundation

/// Service responsible for importing audio files into the music library
/// Implements the import pipeline with upsert logic for Artists, Albums, Releases, and Tracks
class MusicImportService {
    private let repository: GRDBRepository
    
    init(repository: GRDBRepository) {
        self.repository = repository
    }
    
    /// Import an audio file and create all necessary entities
    /// Returns the created Track with its associated DigitalFile
    func importAudioFile(url: URL) async throws -> Track {
        // Extract metadata from the audio file
        let metadata = try await extractMetadata(from: url)
        
        // Upsert Artist
        let artist = try await repository.upsertArtist(
            name: metadata.albumArtistName ?? metadata.artistName,
            sortName: nil
        )
        
        // Upsert Album
        let album = try await repository.upsertAlbum(
            artistId: artist.id,
            title: metadata.albumName,
            albumArtistName: metadata.albumArtistName,
            composerName: metadata.composerName,
            isCompilation: metadata.isCompilation
        )
        
        // Upsert Release (default to Digital format with minimal metadata)
        let release = try await repository.upsertRelease(
            albumId: album.id,
            format: .digital,
            edition: nil,
            label: nil,
            year: metadata.year,
            country: nil,
            catalogNumber: nil,
            barcode: nil,
            discs: 1,
            isCompilation: metadata.isCompilation
        )
        
        // Create Track
        let track = Track(
            id: 0,
            releaseId: release.id,
            discNumber: metadata.discNumber ?? 1,
            trackNumber: metadata.trackNumber,
            title: metadata.title,
            duration: metadata.duration,
            artistName: metadata.artistName,
            albumArtistName: metadata.albumArtistName,
            composerName: metadata.composerName,
            genre: metadata.genre,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let savedTrack = try await repository.saveTrack(track)
        
        // Create DigitalFile
        let digitalFile = DigitalFile(
            id: 0,
            trackId: savedTrack.id,
            fileURL: url,
            bookmarkData: nil,
            fileHash: nil,
            fileSize: try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64,
            addedAt: Date(),
            lastScannedAt: Date(),
            metadataJSON: nil,
            artworkData: metadata.artworkData
        )
        
        let savedDigitalFile = try await repository.saveDigitalFile(digitalFile)
        
        // Return track with digital file attached
        var trackWithFile = savedTrack
        trackWithFile.digitalFiles = [savedDigitalFile]
        
        return trackWithFile
    }
    
    /// Import multiple audio files
    func importAudioFiles(urls: [URL]) async throws -> [Track] {
        var importedTracks: [Track] = []
        
        for url in urls {
            do {
                let track = try await importAudioFile(url: url)
                importedTracks.append(track)
            } catch {
                print("Failed to import \(url.lastPathComponent): \(error)")
                // Continue with other files
            }
        }
        
        return importedTracks
    }
    
    // MARK: - Metadata Extraction
    
    private func extractMetadata(from url: URL) async throws -> AudioMetadata {
        let asset = AVAsset(url: url)
        
        // Load duration
        var duration: TimeInterval? = nil
        if let cmTime: CMTime = try? await asset.load(.duration) {
            let seconds = CMTimeGetSeconds(cmTime)
            if seconds.isFinite {
                duration = seconds
            }
        }
        
        // Load metadata
        var title = url.deletingPathExtension().lastPathComponent
        var artistName = "Unknown Artist"
        var albumName = "Unknown Album"
        var albumArtistName: String? = nil
        var composerName: String? = nil
        var year: Int? = nil
        var trackNumber: Int? = nil
        var discNumber: Int? = nil
        var genre: String? = nil
        var artworkData: Data? = nil
        var isCompilation = false
        
        // Load common metadata
        if let commonMetadata: [AVMetadataItem] = try? await asset.load(.commonMetadata) {
            for item in commonMetadata {
                let key = item.commonKey?.rawValue
                guard let keyUnwrapped = key else { continue }
                
                let valueString = await extractStringValue(from: item)
                
                switch keyUnwrapped {
                case "title":
                    if let value = valueString {
                        title = value
                    }
                case "artist":
                    if let value = valueString {
                        artistName = value
                    }
                case "albumName":
                    if let value = valueString {
                        albumName = value
                    }
                case "type":
                    if let value = valueString, value.lowercased() == "compilation" {
                        isCompilation = true
                    }
                default:
                    break
                }
                
                // Extract artwork
                if key == "artwork", let data = try? await item.load(.value) as? Data {
                    artworkData = data
                }
            }
        }
        
        // Load format-specific metadata
        if let formats: [AVMetadataFormat] = try? await asset.load(.availableMetadataFormats) {
            for format in formats {
                if let fmtItems = try? await asset.loadMetadata(for: format) {
                    if albumArtistName == nil {
                        albumArtistName = await extractAlbumArtist(from: fmtItems)
                    }

                    if composerName == nil {
                        composerName = await extractComposer(from: fmtItems)
                    }

                    for item in fmtItems {
                        let valueString = await extractStringValue(from: item)
                        
                        // Try to extract year
                        if year == nil {
                            if let key = item.commonKey?.rawValue, key == "creationDate" || key == "year" {
                                year = extractYear(from: valueString)
                            } else if let key = item.key as? String, key.lowercased().contains("year") || key.lowercased().contains("date") {
                                year = extractYear(from: valueString)
                            }
                        }
                        
                        // Try to extract track number
                        if trackNumber == nil {
                            if let key = item.commonKey?.rawValue, key == "trackNumber" {
                                trackNumber = valueString.flatMap { Int($0) }
                            } else if let key = item.key as? String, key.uppercased() == "TRCK" || key == "©trkn" {
                                trackNumber = extractTrackNumber(from: valueString)
                            }
                        }
                        
                        // Try to extract disc number
                        if discNumber == nil {
                            if let key = item.key as? String, key.uppercased() == "TPOS" || key == "©disc" {
                                discNumber = extractDiscNumber(from: valueString)
                            }
                        }
                        
                        // Try to extract genre
                        if genre == nil {
                            if let key = item.commonKey?.rawValue, key == "type" {
                                if let value = valueString, !value.isEmpty && value.lowercased() != "compilation" {
                                    genre = value
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return AudioMetadata(
            title: title,
            artistName: artistName,
            albumName: albumName,
            albumArtistName: albumArtistName,
            composerName: composerName,
            year: year,
            trackNumber: trackNumber,
            discNumber: discNumber,
            genre: genre,
            duration: duration,
            artworkData: artworkData,
            isCompilation: isCompilation
        )
    }
    
    private func extractStringValue(from item: AVMetadataItem) async -> String? {
        if let sv: String = try? await item.load(.stringValue) {
            return sv
        }
        if let v = try? await item.load(.value) {
            if let s = v as? String { return s }
            if let n = v as? NSNumber { return n.stringValue }
            return String(describing: v)
        }
        return nil
    }
    
    private func extractAlbumArtist(from metadataItems: [AVMetadataItem]) async -> String? {
        for item in metadataItems {
            // Prefer commonKey if present
            if let ck = item.commonKey?.rawValue, ck == "albumArtist", let v = await extractStringValue(from: item) {
                return v
            }
            
            // ID3v2: Album artist frame is "TPE2"
            if item.keySpace == .id3 {
                if let key = item.key as? String, key == "TPE2", let v = await extractStringValue(from: item) {
                    return v
                }
            }
            
            // MP4 / iTunes metadata: album artist key is "aART"
            if item.keySpace == .iTunes {
                if let key = item.key as? String, key == "aART", let v = await extractStringValue(from: item) {
                    return v
                }
            }
            
            // Some files may expose album artist via the item's identifier
            if let id = item.identifier?.rawValue.lowercased(), id.contains("albumartist") || id.contains("aart"), let v = await extractStringValue(from: item) {
                return v
            }
        }
        
        return nil
    }
    
    private func extractComposer(from metadataItems: [AVMetadataItem]) async -> String? {
        for item in metadataItems {
            if let ck = item.commonKey?.rawValue, ck == "creator", let v = await extractStringValue(from: item) {
                return v
            }
            
            // ID3v2: Composer frame is "TCOM"
            if item.keySpace == .id3 {
                if let key = item.key as? String, key == "TCOM", let v = await extractStringValue(from: item) {
                    return v
                }
            }
            
            // MP4 / iTunes metadata: composer key is "©wrt"
            if item.keySpace == .iTunes {
                if let key = item.key as? String, key == "©wrt", let v = await extractStringValue(from: item) {
                    return v
                }
            }
        }
        
        return nil
    }
    
    private func extractYear(from string: String?) -> Int? {
        guard let string = string else { return nil }
        
        // Try direct conversion
        if let year = Int(string) {
            return year
        }
        
        // Try to extract year from date string (e.g., "2023-01-15")
        let yearPattern = #/(\d{4})/#
        if let match = try? yearPattern.firstMatch(in: string) {
            return Int(match.1)
        }
        
        return nil
    }
    
    private func extractTrackNumber(from string: String?) -> Int? {
        guard let string = string else { return nil }
        
        // Handle "5/12" format (track 5 of 12)
        if let slashIndex = string.firstIndex(of: "/") {
            let trackPart = String(string[..<slashIndex])
            return Int(trackPart)
        }
        
        return Int(string)
    }
    
    private func extractDiscNumber(from string: String?) -> Int? {
        guard let string = string else { return nil }
        
        // Handle "2/3" format (disc 2 of 3)
        if let slashIndex = string.firstIndex(of: "/") {
            let discPart = String(string[..<slashIndex])
            return Int(discPart)
        }
        
        return Int(string)
    }
}

// MARK: - Supporting Types

struct AudioMetadata {
    let title: String
    let artistName: String
    let albumName: String
    let albumArtistName: String?
    let composerName: String?
    let year: Int?
    let trackNumber: Int?
    let discNumber: Int?
    let genre: String?
    let duration: TimeInterval?
    let artworkData: Data?
    let isCompilation: Bool
}
