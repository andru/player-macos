import XCTest
@testable import MusicPlayer

final class PreferencesManagerTests: XCTestCase {
    
    let playbackBehaviorKey = "PlaybackBehavior"
    
    override func setUp() {
        super.setUp()
        // Clear any existing preferences before each test
        UserDefaults.standard.removeObject(forKey: playbackBehaviorKey)
    }
    
    override func tearDown() {
        // Clean up after each test
        UserDefaults.standard.removeObject(forKey: playbackBehaviorKey)
        super.tearDown()
    }
    
    // MARK: - Default Value Tests
    
    @MainActor
    func testDefaultPlaybackBehavior() {
        // Given: No saved preference exists
        XCTAssertNil(UserDefaults.standard.string(forKey: playbackBehaviorKey))
        
        // When: Creating a new PreferencesManager
        let manager = PreferencesManager()
        
        // Then: Should default to clearAndPlay
        XCTAssertEqual(manager.playbackBehavior, .clearAndPlay)
    }
    
    // MARK: - Persistence Tests
    
    @MainActor
    func testPlaybackBehaviorClearAndPlayPersistence() {
        // Given: Create a manager and set behavior
        let manager = PreferencesManager()
        
        // When: Set to clearAndPlay
        manager.playbackBehavior = .clearAndPlay
        
        // Then: Value should be persisted
        let savedValue = UserDefaults.standard.string(forKey: playbackBehaviorKey)
        XCTAssertEqual(savedValue, PlaybackBehavior.clearAndPlay.rawValue)
    }
    
    @MainActor
    func testPlaybackBehaviorAppendToQueuePersistence() {
        // Given: Create a manager and set behavior
        let manager = PreferencesManager()
        
        // When: Set to appendToQueue
        manager.playbackBehavior = .appendToQueue
        
        // Then: Value should be persisted
        let savedValue = UserDefaults.standard.string(forKey: playbackBehaviorKey)
        XCTAssertEqual(savedValue, PlaybackBehavior.appendToQueue.rawValue)
    }
    
    @MainActor
    func testPlaybackBehaviorRestoration() {
        // Given: Save a preference directly to UserDefaults
        UserDefaults.standard.set(PlaybackBehavior.appendToQueue.rawValue, forKey: playbackBehaviorKey)
        
        // When: Create a new manager (simulating app restart)
        let manager = PreferencesManager()
        
        // Then: Should restore the saved value
        XCTAssertEqual(manager.playbackBehavior, .appendToQueue)
    }
    
    // MARK: - PlaybackBehavior Enum Tests
    
    func testPlaybackBehaviorCaseIterable() {
        // Given/When: Access all cases
        let allCases = PlaybackBehavior.allCases
        
        // Then: Should have exactly two cases
        XCTAssertEqual(allCases.count, 2)
        XCTAssertTrue(allCases.contains(.clearAndPlay))
        XCTAssertTrue(allCases.contains(.appendToQueue))
    }
    
    func testPlaybackBehaviorRawValues() {
        // Given/When/Then: Verify raw values are descriptive
        XCTAssertEqual(PlaybackBehavior.clearAndPlay.rawValue, "Clear queue and play immediately")
        XCTAssertEqual(PlaybackBehavior.appendToQueue.rawValue, "Append to end of queue")
    }
}
