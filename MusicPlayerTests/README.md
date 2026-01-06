# MusicPlayer Tests

This directory contains unit tests for the MusicPlayer application.

## Test Files

### LibraryManagerSecurityBookmarkTests.swift

Tests for security bookmark functionality in the LibraryManager class. These tests verify:

#### Bookmark Creation
- `testDirectoryBookmarkIsCreated()` - Verifies that a security-scoped bookmark is created when importing a directory
- `testMultipleDirectoryBookmarksAreStored()` - Ensures multiple directory bookmarks can be stored simultaneously

#### Bookmark Restoration
- `testBookmarkCanBeRestored()` - Validates that a created bookmark can be successfully resolved back to a URL
- `testStaleBookmarkIsDetected()` - Tests that stale bookmarks are properly detected

#### Bookmark Refresh
- `testBookmarkRefreshUpdatesUserDefaults()` - Ensures that when a bookmark is refreshed, UserDefaults is updated with the new bookmark data

#### Recursive Import
- `testRecursiveDirectoryScanFindsAllMusicFiles()` - Verifies that the recursive directory scan finds music files in nested subdirectories

#### Security Scope
- `testSecurityScopeAccessIsProperlyManaged()` - Tests that security-scoped resource access is properly started and stopped
- `testBookmarkDataIsValidSecurityScopedBookmark()` - Validates that created bookmarks are proper security-scoped bookmarks

## Running Tests

### In Xcode
1. Open `MusicPlayer.xcodeproj` in Xcode
2. Select the MusicPlayerTests scheme
3. Press Cmd+U to run all tests
4. Or use the Test Navigator (Cmd+6) to run individual tests

### From Command Line
```bash
xcodebuild test -project MusicPlayer.xcodeproj -scheme MusicPlayerTests
```

## Test Coverage

The tests focus on the critical security bookmark functionality:
- Creating bookmarks for user-selected directories
- Storing bookmarks in UserDefaults
- Restoring bookmarks on app launch
- Refreshing stale bookmarks
- Managing security-scoped resource access

## Notes

- Tests use temporary directories to avoid interfering with actual user data
- UserDefaults is cleaned up before and after each test
- Tests create minimal test files (empty Data objects) since metadata extraction is not the focus
- The tests verify the bookmark mechanism works correctly, which is essential for maintaining access to user-selected directories in a sandboxed macOS app
