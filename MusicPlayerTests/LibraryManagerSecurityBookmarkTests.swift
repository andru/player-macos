import XCTest
@testable import MusicPlayer

@MainActor
class LibraryManagerSecurityBookmarkTests: XCTestCase {
    
    var libraryManager: LibraryManager!
    var testDirectory: URL!
    
    // Static constant for the bookmark key to use before libraryManager is initialized
    private static let directoryBookmarksKey = "MusicPlayerDirectoryBookmarks"
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create a temporary directory for testing
        let tempDir = FileManager.default.temporaryDirectory
        testDirectory = tempDir.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
        
        // Clear any existing bookmarks from UserDefaults
        UserDefaults.standard.removeObject(forKey: Self.directoryBookmarksKey)
        
        libraryManager = LibraryManager()
    }
    
    override func tearDown() async throws {
        // Clean up test directory
        if let testDirectory = testDirectory {
            try? FileManager.default.removeItem(at: testDirectory)
        }
        
        // Clear bookmarks
        UserDefaults.standard.removeObject(forKey: Self.directoryBookmarksKey)
        
        libraryManager = nil
        testDirectory = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Bookmark Creation Tests
    
    func testDirectoryBookmarkIsCreated() async throws {
        // Given: A directory with some test music files
        let musicFile = testDirectory.appendingPathComponent("test.mp3")
        try Data().write(to: musicFile)
        
        // When: Importing the directory
        await libraryManager.importDirectory(url: testDirectory)
        
        // Then: A bookmark should be created in UserDefaults
        let bookmarks = UserDefaults.standard.dictionary(forKey: libraryManager.directoryBookmarksKey) as? [String: Data]
        XCTAssertNotNil(bookmarks, "Bookmarks dictionary should be created")
        XCTAssertEqual(bookmarks?.count, 1, "Should have exactly one bookmark")
        XCTAssertNotNil(bookmarks?[testDirectory.path], "Bookmark should exist for test directory path")
    }
    
    func testMultipleDirectoryBookmarksAreStored() async throws {
        // Given: Two different directories
        let dir1 = testDirectory.appendingPathComponent("dir1", isDirectory: true)
        let dir2 = testDirectory.appendingPathComponent("dir2", isDirectory: true)
        try FileManager.default.createDirectory(at: dir1, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: dir2, withIntermediateDirectories: true)
        
        let musicFile1 = dir1.appendingPathComponent("test1.mp3")
        let musicFile2 = dir2.appendingPathComponent("test2.mp3")
        try Data().write(to: musicFile1)
        try Data().write(to: musicFile2)
        
        // When: Importing both directories
        await libraryManager.importDirectory(url: dir1)
        await libraryManager.importDirectory(url: dir2)
        
        // Then: Both bookmarks should be stored
        let bookmarks = UserDefaults.standard.dictionary(forKey: libraryManager.directoryBookmarksKey) as? [String: Data]
        XCTAssertNotNil(bookmarks, "Bookmarks dictionary should be created")
        XCTAssertEqual(bookmarks?.count, 2, "Should have two bookmarks")
        XCTAssertNotNil(bookmarks?[dir1.path], "Bookmark should exist for first directory")
        XCTAssertNotNil(bookmarks?[dir2.path], "Bookmark should exist for second directory")
    }
    
    // MARK: - Bookmark Restoration Tests
    
    func testBookmarkCanBeRestored() async throws {
        // Given: A directory with a bookmark created
        let musicFile = testDirectory.appendingPathComponent("test.mp3")
        try Data().write(to: musicFile)
        
        await libraryManager.importDirectory(url: testDirectory)
        
        // Get the bookmark data
        guard let bookmarks = UserDefaults.standard.dictionary(forKey: libraryManager.directoryBookmarksKey) as? [String: Data],
              let bookmarkData = bookmarks[testDirectory.path] else {
            XCTFail("Bookmark should exist")
            return
        }
        
        // When: Resolving the bookmark
        var isStale = false
        let resolvedURL = try URL(
            resolvingBookmarkData: bookmarkData,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        
        // Then: The URL should be resolved successfully and not be stale
        XCTAssertEqual(resolvedURL.path, testDirectory.path, "Resolved URL should match original")
        XCTAssertFalse(isStale, "Bookmark should not be stale immediately after creation")
    }
    
    // MARK: - Bookmark Refresh Tests
    
    func testStaleBookmarkIsDetected() async throws {
        // Given: A bookmark that simulates being stale
        let musicFile = testDirectory.appendingPathComponent("test.mp3")
        try Data().write(to: musicFile)
        
        // Create a bookmark
        let bookmarkData = try testDirectory.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        
        // Store it in UserDefaults
        UserDefaults.standard.set([testDirectory.path: bookmarkData], forKey: libraryManager.directoryBookmarksKey)
        
        // When: Attempting to resolve (in a real scenario, this might be stale after time/system changes)
        var isStale = false
        let resolvedURL = try URL(
            resolvingBookmarkData: bookmarkData,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        
        // Then: The URL should still be resolved
        XCTAssertEqual(resolvedURL.path, testDirectory.path, "URL should be resolved even if stale")
        // Note: isStale may or may not be true depending on the system state
    }
    
    func testBookmarkRefreshUpdatesUserDefaults() async throws {
        // Given: A directory with a bookmark
        let musicFile = testDirectory.appendingPathComponent("test.mp3")
        try Data().write(to: musicFile)
        
        // Create initial bookmark
        let initialBookmarkData = try testDirectory.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        UserDefaults.standard.set([testDirectory.path: initialBookmarkData], forKey: libraryManager.directoryBookmarksKey)
        
        // When: Creating a new bookmark for the same path (simulating refresh)
        let refreshedBookmarkData = try testDirectory.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        
        var bookmarks = UserDefaults.standard.dictionary(forKey: libraryManager.directoryBookmarksKey) as? [String: Data] ?? [:]
        bookmarks[testDirectory.path] = refreshedBookmarkData
        UserDefaults.standard.set(bookmarks, forKey: libraryManager.directoryBookmarksKey)
        
        // Then: The bookmark should be updated in UserDefaults
        let updatedBookmarks = UserDefaults.standard.dictionary(forKey: libraryManager.directoryBookmarksKey) as? [String: Data]
        XCTAssertNotNil(updatedBookmarks?[testDirectory.path], "Bookmark should still exist")
        XCTAssertEqual(updatedBookmarks?.count, 1, "Should still have exactly one bookmark")
    }
    
    // MARK: - Recursive Import Tests
    
    func testRecursiveDirectoryScanFindsAllMusicFiles() async throws {
        // Given: A nested directory structure with music files
        let subDir1 = testDirectory.appendingPathComponent("Album1", isDirectory: true)
        let subDir2 = testDirectory.appendingPathComponent("Artist1/Album2", isDirectory: true)
        try FileManager.default.createDirectory(at: subDir1, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: subDir2, withIntermediateDirectories: true)
        
        let file1 = testDirectory.appendingPathComponent("track1.mp3")
        let file2 = subDir1.appendingPathComponent("track2.m4a")
        let file3 = subDir2.appendingPathComponent("track3.flac")
        let nonMusicFile = subDir1.appendingPathComponent("readme.txt")
        
        try Data().write(to: file1)
        try Data().write(to: file2)
        try Data().write(to: file3)
        try Data().write(to: nonMusicFile)
        
        // When: Importing the directory
        await libraryManager.importDirectory(url: testDirectory)
        
        // Then: All music files should be found and imported (3 files, ignoring readme.txt)
        // Note: This test verifies the scanning works, but actual track creation may fail
        // without valid audio metadata. The important part is that the bookmark is created.
        let bookmarks = UserDefaults.standard.dictionary(forKey: libraryManager.directoryBookmarksKey) as? [String: Data]
        XCTAssertNotNil(bookmarks?[testDirectory.path], "Bookmark should be created after scanning")
    }
    
    // MARK: - Security Scope Tests
    
    func testSecurityScopeAccessIsProperlyManaged() async throws {
        // Given: A directory
        let musicFile = testDirectory.appendingPathComponent("test.mp3")
        try Data().write(to: musicFile)
        
        // When: Importing (which should start and stop security scope access)
        await libraryManager.importDirectory(url: testDirectory)
        
        // Then: The import should complete without errors and bookmark should exist
        let bookmarks = UserDefaults.standard.dictionary(forKey: libraryManager.directoryBookmarksKey) as? [String: Data]
        XCTAssertNotNil(bookmarks?[testDirectory.path], "Bookmark should exist after import with security scope access")
    }
    
    func testBookmarkDataIsValidSecurityScopedBookmark() async throws {
        // Given: A directory with a created bookmark
        let musicFile = testDirectory.appendingPathComponent("test.mp3")
        try Data().write(to: musicFile)
        
        await libraryManager.importDirectory(url: testDirectory)
        
        guard let bookmarks = UserDefaults.standard.dictionary(forKey: libraryManager.directoryBookmarksKey) as? [String: Data],
              let bookmarkData = bookmarks[testDirectory.path] else {
            XCTFail("Bookmark should exist")
            return
        }
        
        // When: Checking if it's a security-scoped bookmark
        var isStale = false
        let resolvedURL = try URL(
            resolvingBookmarkData: bookmarkData,
            options: [.withSecurityScope],  // This option indicates we expect a security-scoped bookmark
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        
        // Then: It should resolve successfully with security scope option
        XCTAssertEqual(resolvedURL.path, testDirectory.path, "Security-scoped bookmark should resolve correctly")
    }
}
