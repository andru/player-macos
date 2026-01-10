import Foundation

/// A Recording as sequenced on a Medium
struct Track: Identifiable, Hashable {
    let id: Int64
    var mediumId: Int64
    var recordingId: Int64
    var position: Int  // track number on medium
    var titleOverride: String?  // if different from recording title
    var createdAt: Date
    var updatedAt: Date
    
    // Transient properties (not persisted, loaded via relationships)
    var recording: Recording?
    var medium: Medium?
    
    init(
        id: Int64,
        mediumId: Int64,
        recordingId: Int64,
        position: Int,
        titleOverride: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        recording: Recording? = nil,
        medium: Medium? = nil
    ) {
        self.id = id
        self.mediumId = mediumId
        self.recordingId = recordingId
        self.position = position
        self.titleOverride = titleOverride
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.recording = recording
        self.medium = medium
    }
    
    var title: String {
        titleOverride ?? recording?.title ?? "Unknown"
    }
    
    var duration: TimeInterval? {
        recording?.duration
    }

    var formattedDuration: String {
        guard let duration = duration else { return "--:--" }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var hasDigitalFiles: Bool {
        recording?.hasDigitalFiles ?? false
    }
    
    enum CodingKeys: String, CodingKey {
        case id, mediumId, recordingId, position, titleOverride, createdAt, updatedAt
    }
    
    func toPlayerMedia() -> PlayerMedia? {
        // Safely unwrap recording and its first digital file. Return nil if not available.
        guard let recording = recording, recording.hasDigitalFiles,
              let digitalFile = recording.digitalFiles.first else {
            return nil
        }

        return PlayerMedia(
            id: id,
            title: title,
            artist: recording.artists.first?.name ?? "Unknown Artist",
            album: medium?.release?.releaseGroup?.title ?? "Unknown Album",
            albumArtist: medium?.release?.releaseGroup?.primaryArtist?.name ?? "Unknown Artist",
            duration: recording.duration ?? 0,
            fileURL: digitalFile.fileURL,
            artworkURL: nil,
            artworkData: digitalFile.artworkData,
            genre: "None",
            year: medium?.release?.year,
            trackNumber: position,
            digitalFile: digitalFile
        )
    }
}
