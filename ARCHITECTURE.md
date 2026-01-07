# GRDB Architecture

## Overview

This document describes the database persistence layer using GRDB and GRDBQuery, providing a clean, testable, and iOS-portable architecture with built-in migrations and observable queries.

## Problem Statement

The original implementation had several issues:
- `DatabaseManager` used raw SQLite3 C API, requiring manual memory management
- Manual migration management with version tracking
- No observable queries
- Thread-safety required custom DispatchQueue management
- Verbose code for common operations

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

### 3. GRDB Repository Implementation

**Location:** `MusicPlayer/Repositories/GRDBRepository.swift`

**Key Features:**
- Implements both `TrackRepository` and `CollectionRepository` protocols
- Uses GRDB's built-in thread-safe DatabaseQueue
- Declarative migrations with DatabaseMigrator
- Type-safe queries with Codable records
- Automatic transaction management
- No manual memory management needed

**GRDB Record Types:**
```swift
struct TrackRecord: Codable, FetchableRecord, PersistableRecord {
    var id: String
    var title: String
    // ... other fields
    
    static let databaseTableName = "tracks"
}
```

**Migration with GRDB:**
```swift
var migrator = DatabaseMigrator()

migrator.registerMigration("v1") { db in
    try db.create(table: "tracks") { t in
        t.column("id", .text).primaryKey()
        t.column("title", .text).notNull()
        // ... other columns
    }
}

try migrator.migrate(db)
```

**Benefits:**
- Built-in migration system with version tracking
- Type-safe database access
- Thread-safe by default
- Concise, declarative syntax
- Compatible with GRDBQuery for observable queries

### 4. Migration Management

**Built into GRDB**

GRDB provides a built-in migration system that:
- Tracks versions automatically
- Ensures migrations run only once
- Provides rollback safety
- Uses transactions for atomic updates

**Example:**
```swift
var migrator = DatabaseMigrator()

migrator.registerMigration("v1") { db in
    try db.create(table: "tracks") { t in
        t.column("id", .text).primaryKey()
        t.column("title", .text).notNull()
        // ... other columns
    }
}

// Future migrations
migrator.registerMigration("v2") { db in
    try db.alter(table: "tracks") { t in
        t.add(column: "playCount", .integer).defaults(to: 0)
    }
}

try migrator.migrate(db)
```

### 5. Database Manager Facade

**Location:** `MusicPlayer/Managers/DatabaseManager.swift`

**Purpose:**
- Simple async API for LibraryManager
- Delegates to GRDBRepository
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

GRDB schema is defined declaratively using the DatabaseMigrator.

### Tables

**tracks**
```swift
try db.create(table: "tracks") { t in
    t.column("id", .text).primaryKey()
    t.column("title", .text).notNull()
    t.column("artist", .text).notNull()
    t.column("album", .text).notNull()
    t.column("albumArtist", .text)
    t.column("duration", .double).notNull()
    t.column("fileURL", .text).notNull()
    t.column("artworkURL", .text)
    t.column("artworkData", .blob)
    t.column("genre", .text)
    t.column("year", .integer)
    t.column("trackNumber", .integer)
}
```

**collections**
```swift
try db.create(table: "collections") { t in
    t.column("id", .text).primaryKey()
    t.column("name", .text).notNull()
}
```

**collection_tracks** (junction table)
```swift
try db.create(table: "collection_tracks") { t in
    t.column("collectionId", .text).notNull()
    t.column("trackId", .text).notNull()
    t.column("position", .integer).notNull()
    t.primaryKey(["collectionId", "trackId"])
    t.foreignKey(["collectionId"], references: "collections", onDelete: .cascade)
    t.foreignKey(["trackId"], references: "tracks", onDelete: .cascade)
}
```

### Indexes

For optimal query performance:
```swift
try db.create(index: "idx_tracks_artist", on: "tracks", columns: ["artist"])
try db.create(index: "idx_tracks_album", on: "tracks", columns: ["album"])
try db.create(index: "idx_tracks_album_artist", on: "tracks", columns: ["albumArtist"])
try db.create(index: "idx_collection_tracks_collection", on: "collection_tracks", columns: ["collectionId"])
```

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

### From Raw SQLite to GRDB

The database schema remains compatible, allowing seamless migration:

1. GRDB reads the existing database file
2. Runs any pending migrations
3. All future operations use GRDB APIs
4. Existing data is preserved

### Adding New Features

With GRDB's migration system:
```swift
migrator.registerMigration("v2") { db in
    try db.alter(table: "tracks") { t in
        t.add(column: "playCount", .integer).defaults(to: 0)
    }
}
```

## Benefits

### GRDB Advantages
- Type-safe database access with Codable
- Built-in migration system
- Thread-safe by default
- Concise, declarative syntax
- Compatible with SwiftUI via GRDBQuery
- No manual memory management
- Automatic transaction handling

### Portability
- Core domain models are pure Swift
- Can be used on iOS without modification
- Platform-specific code isolated to extensions

### Performance
- Database I/O on background queue (handled by GRDB)
- Indexed queries for fast lookups
- Atomic transactions ensure consistency
- Connection pooling and statement caching

### Testability
- Repository protocols enable easy mocking
- Clear interfaces between layers
- GRDB provides in-memory databases for testing

### Maintainability
- Declarative schema definitions
- Type-safe queries
- Less boilerplate code
- Clear separation of concerns

### Extensibility
- Easy to add observable queries with GRDBQuery
- Simple to add new migrations
- Protocol-based design supports dependency injection

## Code Quality Improvements

GRDB migration provides:

1. **Type Safety** - Codable records eliminate stringly-typed queries
2. **Concise Code** - Declarative syntax reduces boilerplate
3. **Built-in Migrations** - No custom version tracking needed
4. **Thread Safety** - DatabaseQueue handles synchronization
5. **Observable Queries** - GRDBQuery enables reactive UI updates

## Future Enhancements

Potential improvements enabled by GRDB:

1. **Observable Queries with GRDBQuery**
   - Real-time UI updates when data changes
   - SwiftUI-friendly ValueObservation
   - Automatic refresh on database changes

2. **Advanced Queries**
   - Full-text search with FTS5
   - Complex joins and aggregations
   - Custom SQL with type-safe results

3. **Cloud Sync**
   - Implement CloudKitRepository conforming to same protocols
   - Sync changes between devices

4. **Performance Optimizations**
   - Batch operations with better error handling
   - Prepared statements caching (automatic)
   - Incremental loading for large libraries

## Files Changed

### New Files
- `MusicPlayer/Repositories/GRDBRepository.swift` - GRDB-based repository implementation
- `MusicPlayer/Repositories/TrackRepository.swift` - Repository protocol
- `MusicPlayer/Repositories/CollectionRepository.swift` - Repository protocol
- `MusicPlayer/Models/Track+macOS.swift` - Platform-specific extensions
- `MusicPlayer/Models/Album+macOS.swift` - Platform-specific extensions
- `ARCHITECTURE.md` (this file)

### Modified Files
- `MusicPlayer/Managers/DatabaseManager.swift` - Updated to use GRDBRepository
- `MusicPlayer.xcodeproj/project.pbxproj` - Added GRDB and GRDBQuery packages

### Deprecated Files (can be removed)
- `MusicPlayer/Repositories/SQLiteRepository.swift` - Replaced by GRDBRepository
- `MusicPlayer/Repositories/DatabaseMigrationManager.swift` - GRDB handles migrations

## Conclusion

The migration to GRDB transforms the database layer from manual SQLite3 C API usage into a modern, type-safe, declarative system that is:
- **Type-safe** - Codable records eliminate string-based queries
- **Concise** - Less boilerplate, more readable code
- **Thread-safe** - Built-in synchronization
- **Maintainable** - Declarative schema and migrations
- **Extensible** - Easy to add features with GRDBQuery

GRDB provides a solid foundation for future enhancements like observable queries, full-text search, and reactive UI updates.
