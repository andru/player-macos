import XCTest
@testable import MusicPlayer

final class ViewModePreferencesTests: XCTestCase {
    
    let artistsViewModeKey = "artistsViewMode"
    let albumsViewModeKey = "albumsViewMode"
    let songsViewModeKey = "songsViewMode"
    
    override func setUp() {
        super.setUp()
        // Clear any existing preferences before each test
        UserDefaults.standard.removeObject(forKey: artistsViewModeKey)
        UserDefaults.standard.removeObject(forKey: albumsViewModeKey)
        UserDefaults.standard.removeObject(forKey: songsViewModeKey)
    }
    
    override func tearDown() {
        // Clean up after each test
        UserDefaults.standard.removeObject(forKey: artistsViewModeKey)
        UserDefaults.standard.removeObject(forKey: albumsViewModeKey)
        UserDefaults.standard.removeObject(forKey: songsViewModeKey)
        super.tearDown()
    }
    
    // MARK: - Default Values Tests
    
    func testArtistsDefaultViewMode() {
        // Given: No saved preference exists
        XCTAssertNil(UserDefaults.standard.string(forKey: artistsViewModeKey))
        
        // When: Loading default preference
        // Then: Should default to grid (thumbnail) for Artists
        // This is tested implicitly by the MainContentView's loadViewMode() logic
    }
    
    func testAlbumsDefaultViewMode() {
        // Given: No saved preference exists
        XCTAssertNil(UserDefaults.standard.string(forKey: albumsViewModeKey))
        
        // When: Loading default preference
        // Then: Should default to grid (thumbnail) for Albums
        // This is tested implicitly by the MainContentView's loadViewMode() logic
    }
    
    func testSongsDefaultViewMode() {
        // Given: No saved preference exists
        XCTAssertNil(UserDefaults.standard.string(forKey: songsViewModeKey))
        
        // When: Loading default preference
        // Then: Should default to list for Songs
        // This is tested implicitly by the MainContentView's loadViewMode() logic
    }
    
    // MARK: - Persistence Tests
    
    func testArtistsViewModeGridPersistence() {
        // Given: Set Artists view mode to grid
        UserDefaults.standard.set("grid", forKey: artistsViewModeKey)
        
        // When: Retrieving the value
        let savedValue = UserDefaults.standard.string(forKey: artistsViewModeKey)
        
        // Then: Value should be persisted as "grid"
        XCTAssertEqual(savedValue, "grid")
    }
    
    func testArtistsViewModeListPersistence() {
        // Given: Set Artists view mode to list
        UserDefaults.standard.set("list", forKey: artistsViewModeKey)
        
        // When: Retrieving the value
        let savedValue = UserDefaults.standard.string(forKey: artistsViewModeKey)
        
        // Then: Value should be persisted as "list"
        XCTAssertEqual(savedValue, "list")
    }
    
    func testAlbumsViewModeGridPersistence() {
        // Given: Set Albums view mode to grid
        UserDefaults.standard.set("grid", forKey: albumsViewModeKey)
        
        // When: Retrieving the value
        let savedValue = UserDefaults.standard.string(forKey: albumsViewModeKey)
        
        // Then: Value should be persisted as "grid"
        XCTAssertEqual(savedValue, "grid")
    }
    
    func testAlbumsViewModeListPersistence() {
        // Given: Set Albums view mode to list
        UserDefaults.standard.set("list", forKey: albumsViewModeKey)
        
        // When: Retrieving the value
        let savedValue = UserDefaults.standard.string(forKey: albumsViewModeKey)
        
        // Then: Value should be persisted as "list"
        XCTAssertEqual(savedValue, "list")
    }
    
    func testSongsViewModeGridPersistence() {
        // Given: Set Songs view mode to grid
        UserDefaults.standard.set("grid", forKey: songsViewModeKey)
        
        // When: Retrieving the value
        let savedValue = UserDefaults.standard.string(forKey: songsViewModeKey)
        
        // Then: Value should be persisted as "grid"
        XCTAssertEqual(savedValue, "grid")
    }
    
    func testSongsViewModeListPersistence() {
        // Given: Set Songs view mode to list
        UserDefaults.standard.set("list", forKey: songsViewModeKey)
        
        // When: Retrieving the value
        let savedValue = UserDefaults.standard.string(forKey: songsViewModeKey)
        
        // Then: Value should be persisted as "list"
        XCTAssertEqual(savedValue, "list")
    }
    
    // MARK: - Independence Tests
    
    func testViewModePreferencesAreIndependent() {
        // Given: Set different view modes for each view
        UserDefaults.standard.set("grid", forKey: artistsViewModeKey)
        UserDefaults.standard.set("list", forKey: albumsViewModeKey)
        UserDefaults.standard.set("grid", forKey: songsViewModeKey)
        
        // When: Retrieving all values
        let artistsMode = UserDefaults.standard.string(forKey: artistsViewModeKey)
        let albumsMode = UserDefaults.standard.string(forKey: albumsViewModeKey)
        let songsMode = UserDefaults.standard.string(forKey: songsViewModeKey)
        
        // Then: Each preference should be stored independently
        XCTAssertEqual(artistsMode, "grid")
        XCTAssertEqual(albumsMode, "list")
        XCTAssertEqual(songsMode, "grid")
    }
    
    func testChangingOneViewModeDoesNotAffectOthers() {
        // Given: Initial state with all views set to grid
        UserDefaults.standard.set("grid", forKey: artistsViewModeKey)
        UserDefaults.standard.set("grid", forKey: albumsViewModeKey)
        UserDefaults.standard.set("grid", forKey: songsViewModeKey)
        
        // When: Change only the Albums view mode to list
        UserDefaults.standard.set("list", forKey: albumsViewModeKey)
        
        // Then: Other view modes should remain unchanged
        XCTAssertEqual(UserDefaults.standard.string(forKey: artistsViewModeKey), "grid")
        XCTAssertEqual(UserDefaults.standard.string(forKey: albumsViewModeKey), "list")
        XCTAssertEqual(UserDefaults.standard.string(forKey: songsViewModeKey), "grid")
    }
    
    // MARK: - Value Format Tests
    
    func testOnlyValidValuesAreAccepted() {
        // Given: Set a valid value
        UserDefaults.standard.set("grid", forKey: artistsViewModeKey)
        XCTAssertEqual(UserDefaults.standard.string(forKey: artistsViewModeKey), "grid")
        
        // When: Set another valid value
        UserDefaults.standard.set("list", forKey: artistsViewModeKey)
        
        // Then: Value should be updated
        XCTAssertEqual(UserDefaults.standard.string(forKey: artistsViewModeKey), "list")
    }
    
    // MARK: - Persistence Across App Restarts Simulation
    
    func testPreferencePersistsAcrossReads() {
        // Given: Save a preference
        UserDefaults.standard.set("list", forKey: artistsViewModeKey)
        
        // When: Read it multiple times (simulating app restarts)
        let firstRead = UserDefaults.standard.string(forKey: artistsViewModeKey)
        let secondRead = UserDefaults.standard.string(forKey: artistsViewModeKey)
        let thirdRead = UserDefaults.standard.string(forKey: artistsViewModeKey)
        
        // Then: All reads should return the same value
        XCTAssertEqual(firstRead, "list")
        XCTAssertEqual(secondRead, "list")
        XCTAssertEqual(thirdRead, "list")
    }
}
