import XCTest
@testable import MusicPlayer

final class PlayerStateTests: XCTestCase {
    
    var audioPlayer: AudioPlayer!
    var playerState: PlayerState!
    
    override func setUp() {
        super.setUp()
        audioPlayer = AudioPlayer()
        playerState = audioPlayer.playerState
    }
    
    override func tearDown() {
        audioPlayer = nil
        playerState = nil
        super.tearDown()
    }
    
    // MARK: - PlayerState Decoupling Tests
    
    func testPlayerStateIsDecoupledFromAudioPlayer() {
        // Given: A fresh AudioPlayer instance
        // Then: PlayerState should be accessible as a separate object
        XCTAssertNotNil(audioPlayer.playerState)
        XCTAssertIdentical(playerState, audioPlayer.playerState)
    }
    
    func testPlayerStateInitialValues() {
        // Given: A fresh PlayerState instance
        // Then: All values should be initialized to defaults
        XCTAssertNil(playerState.currentTrack)
        XCTAssertFalse(playerState.isPlaying)
        XCTAssertEqual(playerState.currentTime, 0)
        XCTAssertEqual(playerState.duration, 0)
    }
    
    func testQueueRemainsInAudioPlayer() {
        // Given: An AudioPlayer
        // Then: Queue should be in AudioPlayer, not PlayerState
        XCTAssertNotNil(audioPlayer.queue)
        XCTAssertEqual(audioPlayer.queue.count, 0)
        XCTAssertEqual(audioPlayer.currentQueueIndex, -1)
    }
    
    // MARK: - Album Stable ID Tests
    
    func testAlbumHasStableID() {
        // Given: An album with name and artist
        let album = Album(
            name: "Test Album",
            artist: "Test Artist",
            albumArtist: "Test Album Artist"
        )
        
        // Then: ID should be based on album name and album artist with :: delimiter
        XCTAssertEqual(album.id, "Test Album::Test Album Artist")
    }
    
    func testAlbumIDFallsBackToArtist() {
        // Given: An album without albumArtist
        let album = Album(
            name: "Test Album",
            artist: "Test Artist",
            albumArtist: nil
        )
        
        // Then: ID should use artist instead
        XCTAssertEqual(album.id, "Test Album::Test Artist")
    }
    
    func testAlbumIDIsStableAcrossInstances() {
        // Given: Two albums with same name and artist
        let album1 = Album(
            name: "Test Album",
            artist: "Test Artist"
        )
        
        let album2 = Album(
            name: "Test Album",
            artist: "Test Artist"
        )
        
        // Then: They should have the same ID
        XCTAssertEqual(album1.id, album2.id)
    }
    
    func testAlbumIDDifferentForDifferentAlbums() {
        // Given: Two different albums
        let album1 = Album(
            name: "Album 1",
            artist: "Artist A"
        )
        
        let album2 = Album(
            name: "Album 2",
            artist: "Artist A"
        )
        
        // Then: They should have different IDs
        XCTAssertNotEqual(album1.id, album2.id)
    }
    
    // MARK: - State Update Tests
    
    func testPlayerStateUpdatesWhenTrackChanges() {
        // Given: A track with a temporary file URL
        let tempDir = FileManager.default.temporaryDirectory
        let testFileURL = tempDir.appendingPathComponent("test.mp3")
        
        let track = Track(
            title: "Test Song",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            fileURL: testFileURL
        )
        
        // When: Setting current track in player state
        playerState.currentTrack = track
        playerState.duration = track.duration
        
        // Then: State should be updated
        XCTAssertNotNil(playerState.currentTrack)
        XCTAssertEqual(playerState.currentTrack?.title, "Test Song")
        XCTAssertEqual(playerState.duration, 180.0)
    }
    
    func testPlayerStateIsPlayingFlag() {
        // Given: Initial state
        XCTAssertFalse(playerState.isPlaying)
        
        // When: Setting isPlaying to true
        playerState.isPlaying = true
        
        // Then: Flag should be updated
        XCTAssertTrue(playerState.isPlaying)
        
        // When: Setting back to false
        playerState.isPlaying = false
        
        // Then: Flag should be updated
        XCTAssertFalse(playerState.isPlaying)
    }
    
    func testPlayerStateCurrentTimeUpdates() {
        // Given: Initial time of 0
        XCTAssertEqual(playerState.currentTime, 0)
        
        // When: Updating current time
        playerState.currentTime = 30.5
        
        // Then: Time should be updated
        XCTAssertEqual(playerState.currentTime, 30.5)
    }
}
