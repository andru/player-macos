# Physical Media Music Library Refactoring

## Summary

This implementation refactors the music library data model to support physical media (CD, vinyl, tape) as first-class entities alongside digital files. The new schema introduces Artists, Albums, Releases, and Tracks as persistent entities with proper foreign key relationships.

## What's Been Implemented

### Database Schema (v2_physical_media migration)

- **artists** table: Persistent artist records with name, sortName, timestamps
- **albums** table: Albums belong to an artist, with title, albumArtistName, composerName, compilation flag
- **releases** table: Format-specific editions (CD, Vinyl, Tape, Digital, Other) with edition, label, year, country, catalog details
- **tracks** table: Tracks belong to a release, with disc/track numbers, artistName, genre
- **digital_files** table: Digital files belong to a track (0 to many), with fileURL, artwork, metadata

All tables include proper indexes for search performance.

### Domain Models

- `Artist`: id, name, sortName, createdAt, updatedAt
- `Album`: id, artistId, title, albumArtistName, composerName, isCompilation
- `Release`: id, albumId, format (enum), edition, label, year, country, catalogNumber, barcode, discs
- `Track`: id, releaseId, discNumber, trackNumber, title, duration, artistName
- `DigitalFile`: id, trackId, fileURL, bookmarkData, fileSize, artworkData, metadata

### Repository Layer

- `GRDBRepository`: Implements all repository interfaces with GRDB
- `ArtistRepository`, `AlbumRepository`, `ReleaseRepository`, `TrackRepository`, `DigitalFileRepository`
- Upsert methods for Artists, Albums, and Releases with identity key logic
- Query helpers for relationships and filtering

### Import Pipeline

- `MusicImportService`: Handles audio file import with metadata extraction
- Upserts Artist → Album → Release → Track → DigitalFile
- Release identity based on (albumId, format, edition, label, year, country)
- Defaults to Digital format when metadata is insufficient

### Tests

- Comprehensive test suite in `MusicLibraryRepositoryTests.swift`
- Tests for all CRUD operations
- Tests for upsert logic and relationships
- Tests for physical-only tracks (no digital files)

## Breaking Changes

### Track Model

**Old structure:**
```swift
struct Track {
    let id: UUID
    var title: String
    var artist: String      // Direct string reference
    var album: String       // Direct string reference
    var albumArtist: String?
    var duration: TimeInterval
    var fileURL: URL        // Direct file reference
    var artworkData: Data?  // Direct artwork storage
    var genre: String?
    var year: Int?
    var trackNumber: Int?
}
```

**New structure:**
```swift
struct Track {
    let id: Int64           // Changed from UUID to Int64
    var releaseId: Int64    // Foreign key to Release
    var discNumber: Int
    var trackNumber: Int?
    var title: String
    var duration: TimeInterval?
    var artistName: String  // Denormalized for performance
    var albumArtistName: String?
    var composerName: String?
    var genre: String?
    // Digital files are now separate entities
    var digitalFiles: [DigitalFile]
    var release: Release?   // Navigation property
}
```

### Album Model

**Old structure:**
```swift
struct Album {
    var id: String          // Computed from name + artist
    var name: String
    var artist: String
    var albumArtist: String?
    var artworkData: Data?
    var tracks: [Track]     // Inline array
    var year: Int?
}
```

**New structure:**
```swift
struct Album {
    let id: Int64           // Persistent database ID
    var artistId: Int64     // Foreign key to Artist
    var title: String
    var sortTitle: String?
    var albumArtistName: String?
    var composerName: String?
    var isCompilation: Bool
    var createdAt: Date
    var updatedAt: Date
    var releases: [Release] // Navigation property
    var artist: Artist?     // Navigation property
}
```

### Artist Model

**Old structure:**
```swift
struct Artist {
    let id: UUID
    var name: String
    var albums: [Album]     // Inline array
}
```

**New structure:**
```swift
struct Artist {
    let id: Int64           // Changed from UUID to Int64
    var name: String
    var sortName: String?
    var createdAt: Date
    var updatedAt: Date
    var albums: [Album]     // Navigation property (loaded separately)
}
```

### Collection Model

Track IDs changed from `[UUID]` to `[Int64]` to match new Track ID type.

## What Needs to Be Updated (Future Work)

### LibraryService

`LibraryService` currently uses the old Track structure and needs significant refactoring:

1. **Remove derived albums/artists properties**: These should be loaded from the database, not computed at runtime
2. **Update import methods**: Replace `createTrack()` with calls to `MusicImportService`
3. **Update tracks array**: Consider loading on-demand rather than holding all tracks in memory
4. **Add new query methods**: For artists, albums, releases
5. **Update collection management**: Use Int64 track IDs

### UI Layer

All views currently expect the old data structure:

1. **ArtistsView**: Expects old Artist model with inline albums
2. **AlbumsView**: Expects old Album model with inline tracks
3. **TrackTableView**: Expects old Track with direct file/artwork properties
4. **PlayerControls**: May need updates for new file access pattern

### AudioPlayer

The AudioPlayer likely expects Track to have a `fileURL` property. This needs to be updated to:
- Get the first DigitalFile from a Track
- Handle tracks without digital files gracefully

## Migration Strategy

### For Existing Users

The v2_physical_media migration includes SQL to migrate existing data:
1. Creates Artists from unique (albumArtist ?? artist) values
2. Creates Albums from unique (artist, album) combinations
3. Creates default "Digital" Release for each Album
4. Migrates Tracks to new structure under appropriate Release
5. Migrates file URLs and artwork to DigitalFile records

### For New Development

Use the new APIs:

```swift
// Import an audio file
let track = try await databaseService.importAudioFile(url: fileURL)

// Query structure
let artists = try await databaseService.loadArtists()
let albums = try await databaseService.loadAlbums(forArtistId: artist.id)
let releases = try await databaseService.loadReleases(forAlbumId: album.id)
let tracks = try await databaseService.loadTracks(forReleaseId: release.id)

// Physical media support
let physicalTracks = try await databaseService.loadTracksWithoutDigitalFiles()
```

## Benefits of New Schema

1. **Proper relationships**: Foreign keys ensure data integrity
2. **Physical media support**: Tracks can exist without digital files
3. **Multiple releases**: Same album can have CD, Vinyl, Digital editions
4. **Better performance**: Indexed queries, no runtime aggregation
5. **Scalability**: Supports tens of thousands of tracks efficiently
6. **Clean separation**: Digital files separate from track metadata
7. **Edition tracking**: Label, country, catalog number, barcode support

## Next Steps

1. Update `LibraryService` to use new repository methods
2. Create view models that work with new entity structure
3. Update UI components to use new view models
4. Test migration with real-world music libraries
5. Add UI for editing Artist/Album/Release metadata
6. Add UI for managing physical media entries

## Backward Compatibility

The old database schema (v1) is preserved by the migration system. The v2_physical_media migration:
- Migrates all existing data automatically
- Drops the old tracks table after migration
- Cannot be rolled back (schema recreation is acceptable per requirements)

For testing during transition, a `LegacyTrack` type is available but should not be used for new development.
