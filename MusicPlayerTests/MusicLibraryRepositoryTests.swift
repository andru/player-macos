import XCTest
@testable import MusicPlayer

@MainActor
class MusicLibraryRepositoryTests: XCTestCase {
    
    var repository: GRDBRepository!
    var testDirectory: URL!
    var libraryBundleURL: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create a temporary directory for testing
        let tempDir = FileManager.default.temporaryDirectory
        testDirectory = tempDir.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
        
        // Create library bundle structure
        libraryBundleURL = testDirectory.appendingPathComponent("Test.library", isDirectory: true)
        let contentsURL = libraryBundleURL.appendingPathComponent("Contents", isDirectory: true)
        let resourcesURL = contentsURL.appendingPathComponent("Resources", isDirectory: true)
        try FileManager.default.createDirectory(at: resourcesURL, withIntermediateDirectories: true)
        
        repository = GRDBRepository()
        try await repository.openDatabase(at: libraryBundleURL)
    }
    
    override func tearDown() async throws {
        repository.closeDatabase()
        repository = nil
        
        // Clean up test directory
        if let testDirectory = testDirectory {
            try? FileManager.default.removeItem(at: testDirectory)
        }
        
        testDirectory = nil
        libraryBundleURL = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Artist Tests
    
    func testCreateAndLoadArtist() async throws {
        // Given: A new artist
        let artist = Artist(
            id: 0,
            name: "Radiohead",
            sortName: "Radiohead",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // When: Saving the artist
        let savedArtist = try await repository.saveArtist(artist)
        
        // Then: Artist should be saved with an ID
        XCTAssertNotEqual(savedArtist.id, 0, "Saved artist should have a non-zero ID")
        XCTAssertEqual(savedArtist.name, "Radiohead")
        
        // And: Artist should be loadable
        let loadedArtist = try await repository.loadArtist(id: savedArtist.id, includeAlbums: false)
        XCTAssertNotNil(loadedArtist)
        XCTAssertEqual(loadedArtist?.name, "Radiohead")
    }
    
    func testUpsertArtist() async throws {
        // Given: An artist name
        let artistName = "The Beatles"
        
        // When: Upserting twice with the same name
        let artist1 = try await repository.upsertArtist(name: artistName, sortName: nil)
        let artist2 = try await repository.upsertArtist(name: artistName, sortName: nil)
        
        // Then: Both should return the same artist
        XCTAssertEqual(artist1.id, artist2.id)
        XCTAssertEqual(artist1.name, artistName)
    }
    
    // MARK: - Album Tests
    
    func testCreateAndLoadAlbum() async throws {
        // Given: An artist and an album
        let artist = try await repository.upsertArtist(name: "Radiohead", sortName: nil)
        
        let album = Album(
            id: 0,
            artistId: artist.id,
            title: "OK Computer",
            albumArtistName: "Radiohead",
            isCompilation: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // When: Saving the album
        let savedAlbum = try await repository.saveAlbum(album)
        
        // Then: Album should be saved with an ID
        XCTAssertNotEqual(savedAlbum.id, 0)
        XCTAssertEqual(savedAlbum.title, "OK Computer")
        XCTAssertEqual(savedAlbum.artistId, artist.id)
        
        // And: Album should be loadable
        let loadedAlbum = try await repository.loadAlbum(id: savedAlbum.id, includeReleases: false)
        XCTAssertNotNil(loadedAlbum)
        XCTAssertEqual(loadedAlbum?.title, "OK Computer")
    }
    
    func testLoadAlbumsForArtist() async throws {
        // Given: An artist with multiple albums
        let artist = try await repository.upsertArtist(name: "Radiohead", sortName: nil)
        
        _ = try await repository.upsertAlbum(
            artistId: artist.id,
            title: "OK Computer",
            albumArtistName: "Radiohead",
            composerName: nil,
            isCompilation: false
        )
        
        _ = try await repository.upsertAlbum(
            artistId: artist.id,
            title: "In Rainbows",
            albumArtistName: "Radiohead",
            composerName: nil,
            isCompilation: false
        )
        
        // When: Loading albums for the artist
        let albums = try await repository.loadAlbums(forArtistId: artist.id)
        
        // Then: Should return both albums
        XCTAssertEqual(albums.count, 2)
        XCTAssertTrue(albums.contains { $0.title == "OK Computer" })
        XCTAssertTrue(albums.contains { $0.title == "In Rainbows" })
    }
    
    // MARK: - Release Tests
    
    func testCreateAndLoadRelease() async throws {
        // Given: An artist, album, and release
        let artist = try await repository.upsertArtist(name: "Radiohead", sortName: nil)
        let album = try await repository.upsertAlbum(
            artistId: artist.id,
            title: "In Rainbows",
            albumArtistName: "Radiohead",
            composerName: nil,
            isCompilation: false
        )
        
        let release = Release(
            id: 0,
            albumId: album.id,
            format: .cd,
            edition: nil,
            label: "XL Recordings",
            year: 2007,
            country: "UK",
            discs: 1,
            isCompilation: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // When: Saving the release
        let savedRelease = try await repository.saveRelease(release)
        
        // Then: Release should be saved with an ID
        XCTAssertNotEqual(savedRelease.id, 0)
        XCTAssertEqual(savedRelease.format, .cd)
        XCTAssertEqual(savedRelease.year, 2007)
        
        // And: Release should be loadable
        let loadedRelease = try await repository.loadRelease(id: savedRelease.id, includeTracks: false)
        XCTAssertNotNil(loadedRelease)
        XCTAssertEqual(loadedRelease?.label, "XL Recordings")
    }
    
    func testUpsertReleaseWithIdentityKey() async throws {
        // Given: An album
        let artist = try await repository.upsertArtist(name: "Radiohead", sortName: nil)
        let album = try await repository.upsertAlbum(
            artistId: artist.id,
            title: "In Rainbows",
            albumArtistName: nil,
            composerName: nil,
            isCompilation: false
        )
        
        // When: Upserting a release twice with same identity
        let release1 = try await repository.upsertRelease(
            albumId: album.id,
            format: .cd,
            edition: nil,
            label: "XL Recordings",
            year: 2007,
            country: "UK",
            catalogNumber: nil,
            barcode: nil,
            discs: 1,
            isCompilation: false
        )
        
        let release2 = try await repository.upsertRelease(
            albumId: album.id,
            format: .cd,
            edition: nil,
            label: "XL Recordings",
            year: 2007,
            country: "UK",
            catalogNumber: nil,
            barcode: nil,
            discs: 1,
            isCompilation: false
        )
        
        // Then: Both should return the same release
        XCTAssertEqual(release1.id, release2.id)
    }
    
    func testGetDefaultRelease() async throws {
        // Given: An album with multiple releases
        let artist = try await repository.upsertArtist(name: "Radiohead", sortName: nil)
        let album = try await repository.upsertAlbum(
            artistId: artist.id,
            title: "In Rainbows",
            albumArtistName: nil,
            composerName: nil,
            isCompilation: false
        )
        
        // Create CD and Digital releases
        _ = try await repository.upsertRelease(
            albumId: album.id,
            format: .cd,
            edition: nil,
            label: "XL Recordings",
            year: 2007,
            country: "UK",
            catalogNumber: nil,
            barcode: nil,
            discs: 1,
            isCompilation: false
        )
        
        let digitalRelease = try await repository.upsertRelease(
            albumId: album.id,
            format: .digital,
            edition: nil,
            label: nil,
            year: nil,
            country: nil,
            catalogNumber: nil,
            barcode: nil,
            discs: 1,
            isCompilation: false
        )
        
        // When: Getting default release
        let defaultRelease = try await repository.getDefaultRelease(forAlbumId: album.id)
        
        // Then: Should prefer Digital format
        XCTAssertNotNil(defaultRelease)
        XCTAssertEqual(defaultRelease?.id, digitalRelease.id)
        XCTAssertEqual(defaultRelease?.format, .digital)
    }
    
    // MARK: - Track Tests
    
    func testCreateAndLoadTrack() async throws {
        // Given: A complete entity hierarchy
        let artist = try await repository.upsertArtist(name: "Radiohead", sortName: nil)
        let album = try await repository.upsertAlbum(
            artistId: artist.id,
            title: "OK Computer",
            albumArtistName: "Radiohead",
            composerName: nil,
            isCompilation: false
        )
        let release = try await repository.upsertRelease(
            albumId: album.id,
            format: .digital,
            edition: nil,
            label: nil,
            year: 1997,
            country: nil,
            catalogNumber: nil,
            barcode: nil,
            discs: 1,
            isCompilation: false
        )
        
        let track = Track(
            id: 0,
            releaseId: release.id,
            discNumber: 1,
            trackNumber: 1,
            title: "Airbag",
            duration: 287.0,
            artistName: "Radiohead",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // When: Saving the track
        let savedTrack = try await repository.saveTrack(track)
        
        // Then: Track should be saved with an ID
        XCTAssertNotEqual(savedTrack.id, 0)
        XCTAssertEqual(savedTrack.title, "Airbag")
        XCTAssertEqual(savedTrack.releaseId, release.id)
        
        // And: Track should be loadable
        let loadedTrack = try await repository.loadTrack(id: savedTrack.id, includeDigitalFiles: false)
        XCTAssertNotNil(loadedTrack)
        XCTAssertEqual(loadedTrack?.title, "Airbag")
    }
    
    func testLoadTracksForRelease() async throws {
        // Given: A release with multiple tracks
        let artist = try await repository.upsertArtist(name: "Radiohead", sortName: nil)
        let album = try await repository.upsertAlbum(
            artistId: artist.id,
            title: "OK Computer",
            albumArtistName: nil,
            composerName: nil,
            isCompilation: false
        )
        let release = try await repository.upsertRelease(
            albumId: album.id,
            format: .digital,
            edition: nil,
            label: nil,
            year: nil,
            country: nil,
            catalogNumber: nil,
            barcode: nil,
            discs: 1,
            isCompilation: false
        )
        
        // Create tracks in specific order
        _ = try await repository.saveTrack(Track(
            id: 0,
            releaseId: release.id,
            discNumber: 1,
            trackNumber: 3,
            title: "Subterranean Homesick Alien",
            duration: 267.0,
            artistName: "Radiohead"
        ))
        
        _ = try await repository.saveTrack(Track(
            id: 0,
            releaseId: release.id,
            discNumber: 1,
            trackNumber: 1,
            title: "Airbag",
            duration: 287.0,
            artistName: "Radiohead"
        ))
        
        _ = try await repository.saveTrack(Track(
            id: 0,
            releaseId: release.id,
            discNumber: 1,
            trackNumber: 2,
            title: "Paranoid Android",
            duration: 383.0,
            artistName: "Radiohead"
        ))
        
        // When: Loading tracks with ordering
        let tracks = try await repository.loadTracks(forReleaseId: release.id, orderByDiscAndTrackNumber: true)
        
        // Then: Should return tracks in correct order
        XCTAssertEqual(tracks.count, 3)
        XCTAssertEqual(tracks[0].title, "Airbag")
        XCTAssertEqual(tracks[1].title, "Paranoid Android")
        XCTAssertEqual(tracks[2].title, "Subterranean Homesick Alien")
    }
    
    // MARK: - Digital File Tests
    
    func testCreateAndLoadDigitalFile() async throws {
        // Given: A track
        let artist = try await repository.upsertArtist(name: "Radiohead", sortName: nil)
        let album = try await repository.upsertAlbum(
            artistId: artist.id,
            title: "OK Computer",
            albumArtistName: nil,
            composerName: nil,
            isCompilation: false
        )
        let release = try await repository.upsertRelease(
            albumId: album.id,
            format: .digital,
            edition: nil,
            label: nil,
            year: nil,
            country: nil,
            catalogNumber: nil,
            barcode: nil,
            discs: 1,
            isCompilation: false
        )
        let track = try await repository.saveTrack(Track(
            id: 0,
            releaseId: release.id,
            discNumber: 1,
            trackNumber: 1,
            title: "Airbag",
            artistName: "Radiohead"
        ))
        
        let digitalFile = DigitalFile(
            id: 0,
            trackId: track.id,
            fileURL: URL(fileURLWithPath: "/music/airbag.mp3"),
            fileSize: 10485760,
            addedAt: Date()
        )
        
        // When: Saving the digital file
        let savedFile = try await repository.saveDigitalFile(digitalFile)
        
        // Then: Digital file should be saved with an ID
        XCTAssertNotEqual(savedFile.id, 0)
        XCTAssertEqual(savedFile.fileURL.path, "/music/airbag.mp3")
        XCTAssertEqual(savedFile.trackId, track.id)
        
        // And: Digital file should be loadable
        let loadedFile = try await repository.loadDigitalFile(id: savedFile.id)
        XCTAssertNotNil(loadedFile)
        XCTAssertEqual(loadedFile?.fileURL.path, "/music/airbag.mp3")
    }
    
    func testLoadTracksWithoutDigitalFiles() async throws {
        // Given: Tracks with and without digital files
        let artist = try await repository.upsertArtist(name: "Test Artist", sortName: nil)
        let album = try await repository.upsertAlbum(
            artistId: artist.id,
            title: "Test Album",
            albumArtistName: nil,
            composerName: nil,
            isCompilation: false
        )
        let release = try await repository.upsertRelease(
            albumId: album.id,
            format: .vinyl,
            edition: nil,
            label: nil,
            year: nil,
            country: nil,
            catalogNumber: nil,
            barcode: nil,
            discs: 1,
            isCompilation: false
        )
        
        // Track with digital file
        let trackWithFile = try await repository.saveTrack(Track(
            id: 0,
            releaseId: release.id,
            discNumber: 1,
            trackNumber: 1,
            title: "Track With File",
            artistName: "Test Artist"
        ))
        
        _ = try await repository.saveDigitalFile(DigitalFile(
            id: 0,
            trackId: trackWithFile.id,
            fileURL: URL(fileURLWithPath: "/music/track1.mp3"),
            addedAt: Date()
        ))
        
        // Track without digital file (physical only)
        let trackWithoutFile = try await repository.saveTrack(Track(
            id: 0,
            releaseId: release.id,
            discNumber: 1,
            trackNumber: 2,
            title: "Track Without File",
            artistName: "Test Artist"
        ))
        
        // When: Loading tracks without digital files
        let physicalOnlyTracks = try await repository.loadTracksWithoutDigitalFiles()
        
        // Then: Should only return the track without digital files
        XCTAssertEqual(physicalOnlyTracks.count, 1)
        XCTAssertEqual(physicalOnlyTracks.first?.id, trackWithoutFile.id)
        XCTAssertEqual(physicalOnlyTracks.first?.title, "Track Without File")
    }
}
