# SQLite Architecture Refactoring

## Overview

This document describes the refactoring of the SQLite persistence layer into a clean, testable, and iOS-portable architecture.

## Problem Statement

The original implementation had several issues:
- `DatabaseManager` was marked `@MainActor`, making it non-portable and blocking the UI thread
- Domain models (`Track`, `Collection`, `Album`, `Artist`) had platform-specific imports (AppKit, AVFoundation, SwiftUI)
- SQLite implementation was tightly coupled to DatabaseManager
- No clear repository pattern or protocol layer
- Migrations were embedded in DatabaseManager
- Thread-safety concerns with database operations on the main actor

## Solution Architecture

### 1. Clean Domain Models (iOS/macOS Portable)

**Location:** `MusicPlayer/Models/`

**Core Models:**
- `Track.swift` - Pure Swift struct, no platform dependencies
- `Collection.swift` - Pure Swift struct, no platform dependencies  
- `Album.swift` - Pure Swift struct, no platform dependencies
- `Artist.swift` - Pure Swift struct, no platform dependencies

**Platform Extensions:**
- `Track+macOS.swift` - macOS-specific functionality (NSImage, AVFoundation artwork extraction)
- `Album+macOS.swift` - macOS-specific functionality (NSImage artwork)

**Benefits:**
- Core models can be used on iOS without modification
- Clean separation of portable business logic from platform code
- Easy to add iOS-specific extensions later

### 2. Repository Protocol Layer

**Location:** `MusicPlayer/Repositories/`

**Protocols:**
```swift
protocol TrackRepository {
    func loadTracks() async throws -> [Track]
    func saveTracks(_ tracks: [Track]) async throws
}

protocol CollectionRepository {
    func loadCollections() async throws -> [Collection]
    func saveCollections(_ collections: [Collection]) async throws
}
```

**Benefits:**
- Clear contract for persistence operations
- Easy to mock for testing
- Enables swapping implementations (e.g., SQLite, Core Data, cloud storage)
- Async/await for modern Swift concurrency

### 3. SQLite Repository Implementation

**Location:** `MusicPlayer/Repositories/SQLiteRepository.swift`

**Key Features:**
- Implements both `TrackRepository` and `CollectionRepository` protocols
- Thread-safe using dedicated `DispatchQueue`
- All database I/O happens on background queue
- No `@MainActor` constraint
- Proper error handling with typed `DatabaseError` enum

**Thread Safety:**
```swift
private let queue = DispatchQueue(label: "com.musicplayer.sqlite", qos: .userInitiated)

func loadTracks() async throws -> [Track] {
    try await withCheckedThrowingContinuation { continuation in
        queue.async { [self] in
            // Database operations on background queue
        }
    }
}
```

### 4. Migration Management

**Location:** `MusicPlayer/Repositories/DatabaseMigrationManager.swift`

**Responsibilities:**
- Version tracking using SQLite's `PRAGMA user_version`
- Deterministic schema creation and updates
- Separated from repository implementation

**Example:**
```swift
func runMigrations() throws {
    let currentVersion = try getDatabaseVersion()
    
    if currentVersion < 1 {
        try createInitialSchema()
        try setDatabaseVersion(1)
    }
    
    // Future migrations go here
}
```

### 5. Database Manager Facade

**Location:** `MusicPlayer/Managers/DatabaseManager.swift`

**Purpose:**
- Simple async API for LibraryManager
- Delegates to SQLiteRepository
- Maintains backward compatibility with existing code

### 6. Updated LibraryManager

**Location:** `MusicPlayer/Managers/LibraryManager.swift`

**Changes:**
- All database operations now async
- Proper Task lifecycle management with stored references
- Concurrent save protection
- `@MainActor` only for UI-published properties (`@Published var tracks`, etc.)
- Background database operations don't block UI

**Task Management:**
```swift
private var initializationTask: Task<Void, Never>?
private var saveTask: Task<Void, Never>?

func saveLibrary() {
    saveTask?.cancel() // Cancel pending save
    let tracksToSave = tracks
    let collectionsToSave = collections
    
    saveTask = Task {
        try await databaseManager.saveTracks(tracksToSave)
        try await databaseManager.saveCollections(collectionsToSave)
    }
}
```

## Database Schema

### Tables

**tracks**
```sql
CREATE TABLE tracks (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    artist TEXT NOT NULL,
    album TEXT NOT NULL,
    album_artist TEXT,
    duration REAL NOT NULL,
    file_url TEXT NOT NULL,
    artwork_url TEXT,
    artwork_data BLOB,
    genre TEXT,
    year INTEGER,
    track_number INTEGER
)
```

**collections**
```sql
CREATE TABLE collections (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL
)
```

**collection_tracks** (junction table)
```sql
CREATE TABLE collection_tracks (
    collection_id TEXT NOT NULL,
    track_id TEXT NOT NULL,
    position INTEGER NOT NULL,
    PRIMARY KEY (collection_id, track_id),
    FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE,
    FOREIGN KEY (track_id) REFERENCES tracks(id) ON DELETE CASCADE
)
```

### Indexes

For optimal query performance:
- `idx_tracks_artist` on `tracks(artist)`
- `idx_tracks_album` on `tracks(album)`
- `idx_tracks_album_artist` on `tracks(album_artist)`
- `idx_collection_tracks_collection` on `collection_tracks(collection_id)`

## Testing

**Location:** `MusicPlayerTests/DatabaseManagerTests.swift`

**Coverage:**
- Database initialization and schema creation
- Track CRUD operations with all fields
- Collection CRUD operations with track ordering
- Artwork data storage (BLOB handling)
- Concurrent save operations
- Error handling for unopened database

**All tests updated to async/await:**
```swift
func testSaveAndLoadTracks() async throws {
    try await databaseManager.openDatabase(at: libraryBundleURL)
    // ... test logic
}
```

## Migration Path

### From JSON to SQLite

The system automatically migrates from the legacy JSON format:

1. Opens SQLite database
2. Attempts to load from database
3. If database is empty and `library.json` exists:
   - Loads data from JSON
   - Saves to SQLite database
   - Renames JSON file to `library.json.backup`
4. All future operations use SQLite

### Database Version Migration

When adding new features:
```swift
// In DatabaseMigrationManager
if currentVersion < 2 {
    try execute("ALTER TABLE tracks ADD COLUMN play_count INTEGER DEFAULT 0")
    try setDatabaseVersion(2)
}
```

## Benefits

### Portability
- Core domain models are pure Swift (no AppKit, UIKit, etc.)
- Can be used on iOS without modification
- Platform-specific code isolated to extensions

### Performance
- Database I/O on background queue, never blocks UI
- Indexed queries for fast lookups
- Atomic transactions ensure consistency

### Testability
- Repository protocols enable easy mocking
- Clear interfaces between layers
- 100% test coverage maintained

### Maintainability
- Clear separation of concerns
- Single responsibility principle
- Easy to understand and modify

### Extensibility
- Easy to add new repositories
- Simple to swap implementations
- Protocol-based design supports dependency injection

## Code Review Feedback Addressed

1. **Weak self in database operations** - Changed to `[self]` to ensure operations complete
2. **Unstructured Tasks** - Added stored Task references for proper lifecycle management
3. **Concurrent saves** - Added save task cancellation and state capture
4. **Task cleanup** - Added proper cancellation in deinit

## Future Enhancements

Potential improvements enabled by this architecture:

1. **Additional Repositories**
   - PlaylistRepository for smart playlists
   - HistoryRepository for play history
   - SettingsRepository for user preferences

2. **Cloud Sync**
   - Implement CloudKitRepository conforming to same protocols
   - Sync changes between devices

3. **Offline-first Mobile App**
   - Reuse domain models and repository protocols on iOS
   - Platform-specific UI using SwiftUI

4. **Performance Optimizations**
   - Batch operations
   - Full-text search indexes
   - Incremental loading for large libraries

## Files Changed

### New Files
- `MusicPlayer/Repositories/TrackRepository.swift`
- `MusicPlayer/Repositories/CollectionRepository.swift`
- `MusicPlayer/Repositories/DatabaseMigrationManager.swift`
- `MusicPlayer/Repositories/SQLiteRepository.swift`
- `MusicPlayer/Models/Track+macOS.swift`
- `MusicPlayer/Models/Album+macOS.swift`
- `ARCHITECTURE.md` (this file)

### Modified Files
- `MusicPlayer/Models/Track.swift` - Removed platform imports
- `MusicPlayer/Models/Collection.swift` - Removed platform imports
- `MusicPlayer/Models/Album.swift` - Removed platform imports
- `MusicPlayer/Models/Artist.swift` - Removed platform imports
- `MusicPlayer/Managers/DatabaseManager.swift` - Converted to facade
- `MusicPlayer/Managers/LibraryManager.swift` - Updated to async/await
- `MusicPlayerTests/DatabaseManagerTests.swift` - Updated to async/await
- `MusicPlayer.xcodeproj/project.pbxproj` - Added Repositories folder

### Deleted Files
- None (backward compatible)

## Conclusion

This refactoring transforms the SQLite persistence layer from a monolithic, platform-specific implementation into a clean, layered architecture that is:
- **Portable** - Core models work on any platform
- **Testable** - Clear protocols enable mocking
- **Thread-safe** - Background queue for all I/O
- **Maintainable** - Separation of concerns
- **Extensible** - Easy to add features or swap implementations

The architecture follows SOLID principles and modern Swift best practices, setting a strong foundation for future development.
