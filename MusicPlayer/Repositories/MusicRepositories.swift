import Foundation

/// Protocol defining artist persistence operations
protocol ArtistRepository {
    /// Load all artists from the repository
    func loadArtists() async throws -> [Artist]
    
    /// Load a specific artist by ID with optional relationships
    func loadArtist(id: Int64, includeAlbums: Bool) async throws -> Artist?
    
    /// Save or update an artist
    func saveArtist(_ artist: Artist) async throws -> Artist
    
    /// Find an artist by name
    func findArtist(byName name: String) async throws -> Artist?
    
    /// Upsert an artist by name (create if doesn't exist, return existing if it does)
    func upsertArtist(name: String, sortName: String?) async throws -> Artist
}

/// Protocol defining album persistence operations
protocol AlbumRepository {
    /// Load all albums from the repository
    func loadAlbums() async throws -> [Album]
    
    /// Load albums for a specific artist
    func loadAlbums(forArtistId artistId: Int64) async throws -> [Album]
    
    /// Load a specific album by ID with optional relationships
    func loadAlbum(id: Int64, includeReleases: Bool) async throws -> Album?
    
    /// Save or update an album
    func saveAlbum(_ album: Album) async throws -> Album
    
    /// Find an album by artist ID and title
    func findAlbum(artistId: Int64, title: String) async throws -> Album?
    
    /// Upsert an album (create if doesn't exist, return existing if it does)
    func upsertAlbum(artistId: Int64, title: String, albumArtistName: String?, composerName: String?, isCompilation: Bool) async throws -> Album
}

/// Protocol defining release persistence operations
protocol ReleaseRepository {
    /// Load all releases from the repository
    func loadReleases() async throws -> [Release]
    
    /// Load releases for a specific album
    func loadReleases(forAlbumId albumId: Int64) async throws -> [Release]
    
    /// Load a specific release by ID with optional relationships
    func loadRelease(id: Int64, includeTracks: Bool) async throws -> Release?
    
    /// Save or update a release
    func saveRelease(_ release: Release) async throws -> Release
    
    /// Find a release by album ID and identity key
    func findRelease(albumId: Int64, format: ReleaseFormat, edition: String?, label: String?, year: Int?, country: String?) async throws -> Release?
    
    /// Upsert a release (create if doesn't exist, return existing if it does)
    func upsertRelease(albumId: Int64, format: ReleaseFormat, edition: String?, label: String?, year: Int?, country: String?, catalogNumber: String?, barcode: String?, discs: Int, isCompilation: Bool) async throws -> Release
    
    /// Get the default release for an album (prefer Digital if present)
    func getDefaultRelease(forAlbumId albumId: Int64) async throws -> Release?
}

/// Protocol defining digital file persistence operations
protocol DigitalFileRepository {
    /// Load all digital files from the repository
    func loadDigitalFiles() async throws -> [DigitalFile]
    
    /// Load digital files for a specific track
    func loadDigitalFiles(forTrackId trackId: Int64) async throws -> [DigitalFile]
    
    /// Load a specific digital file by ID
    func loadDigitalFile(id: Int64) async throws -> DigitalFile?
    
    /// Save or update a digital file
    func saveDigitalFile(_ digitalFile: DigitalFile) async throws -> DigitalFile
    
    /// Find a digital file by file URL
    func findDigitalFile(byFileURL fileURL: URL) async throws -> DigitalFile?
    
    /// Load tracks that have no digital files (physical-only media)
    func loadTracksWithoutDigitalFiles() async throws -> [Track]
    
    /// Load tracks that have digital files
    func loadTracksWithDigitalFiles() async throws -> [Track]
}
