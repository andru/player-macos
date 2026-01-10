# MusicBrainz-Aligned Data Model Refactoring

## Overview

This document describes the comprehensive refactoring of the music library data model to align with the MusicBrainz conceptual schema. The refactoring enables proper separation of musical identity, publication, and local storage concerns.

## Key Changes

### 1. New Domain Models

#### Work
- Represents the abstract musical composition ("song as written")
- Fields: `id`, `title`, `createdAt`, `updatedAt`
- Relationships: Many-to-many with Artists (via `work_artist`)

#### Recording
- Represents a specific captured performance of a Work
- Fields: `id`, `title`, `duration`, `createdAt`, `updatedAt`
- Relationships:
  - Many-to-many with Works (via `recording_work`)
  - Many-to-many with Artists (via `recording_artist`)
  - Many-to-many with DigitalFiles (via `recording_digital_file`)
  - One-to-many with Tracks

#### ReleaseGroup
- Represents the album concept that users recognize
- Fields: `id`, `title`, `primaryArtistId`, `isCompilation`, `createdAt`, `updatedAt`
- Relationships:
  - Belongs to one Artist (optional - null for compilations)
  - Has many Releases

#### Label
- Represents a record label
- Fields: `id`, `name`, `sortName`, `createdAt`, `updatedAt`
- Relationships: Many-to-many with Releases (via `release_label`)

#### Medium
- Represents a disc or side within a Release
- Fields: `id`, `releaseId`, `position`, `format`, `title`, `createdAt`, `updatedAt`
- Relationships:
  - Belongs to one Release
  - Has many Tracks

### 2. Updated Domain Models

#### Release
**Before:** A release was tied to an Album with embedded label information
**After:** A release is now tied to a ReleaseGroup with proper label relationships
- Removed: `albumId`, `label`, `discs`, `releaseTitleOverride`, `userNotes`, `isCompilation`
- Added: `releaseGroupId`
- Relationships changed to use Media (plural of Medium) instead of directly having Tracks

#### Track
**Before:** A track contained all metadata (title, artist, album, etc.) and referenced a Release
**After:** A track is now a sequencing of a Recording on a Medium
- Removed: `releaseId`, `discNumber`, `trackNumber`, `title`, `duration`, `artistName`, `albumArtistName`, `composerName`, `genre`
- Added: `mediumId`, `recordingId`, `position`, `titleOverride`
- All metadata is now accessed via the Recording relationship

#### DigitalFile
**Before:** Belonged directly to a Track (one-to-one)
**After:** Has a many-to-many relationship with Recordings
- Removed: `trackId`
- The same recording may exist as multiple encodes
- The same file may later be re-associated if re-identified

#### Album (UI Compatibility Layer)
- No longer a persisted entity
- Now a view model that wraps a ReleaseGroup for backward compatibility with the UI
- Constructor added: `init(from: ReleaseGroup)`

### 3. Database Schema

#### New Tables
- `works` - Musical compositions
- `recordings` - Performances of works
- `labels` - Record labels
- `release_groups` - Album concepts
- `media` - Discs/sides within releases

#### New Join Tables
- `work_artist` - Links works to their creators
- `recording_work` - Links recordings to the works they perform
- `recording_artist` - Links recordings to performing artists
- `release_label` - Links releases to labels
- `recording_digital_file` - Links recordings to their digital files

#### Updated Tables
- `releases` - Now references `releaseGroupId` instead of `albumId`
- `tracks` - Now references `mediumId` and `recordingId` instead of containing metadata
- `digital_files` - No longer references `trackId` directly

#### Removed Tables
- `albums` - Replaced by `release_groups`

### 4. Import Pipeline

The new import pipeline follows the MusicBrainz model:

1. **Extract metadata** from audio file
2. **Upsert Artist(s)** by name
3. **Upsert Work** by title + primary artist heuristic
4. **Upsert Recording** with duration matching, link to Work and Artists
5. **Upsert ReleaseGroup** (album concept)
6. **Upsert Release** under the ReleaseGroup
7. **Upsert Medium** for the disc/side
8. **Create Track** linking Recording to Medium at a position
9. **Create DigitalFile** for the local file
10. **Link Recording to DigitalFile** via junction table

### 5. Repository Layer

#### New Repository Protocols
- `WorkRepository` - CRUD operations for Works
- `RecordingRepository` - CRUD operations for Recordings  
- `LabelRepository` - CRUD operations for Labels
- `ReleaseGroupRepository` - CRUD operations for ReleaseGroups
- `MediumRepository` - CRUD operations for Media

#### Updated Repository Protocols
- `ReleaseRepository` - Now works with ReleaseGroups instead of Albums
- `TrackRepository` - Simplified to basic CRUD
- `DigitalFileRepository` - Now works with Recordings instead of Tracks
- `AlbumRepository` - Maintained for UI compatibility, maps from ReleaseGroups

### 6. Backward Compatibility

To maintain compatibility with the existing UI:

1. **Album model** continues to exist as a view model wrapping ReleaseGroup
2. **AlbumRepository** provides the same interface, internally using ReleaseGroups
3. **DatabaseService** provides facade methods that work with both old and new concepts
4. **LibraryService** continues to work with Albums, Artists, and Tracks

## Benefits

### For Users
- **Physical media support** - Properly model vinyl, CDs, tapes
- **Multi-disc support** - Each disc is a separate Medium
- **Better compilation handling** - ReleaseGroups can have no primary artist
- **Multiple formats** - Same album can exist as CD, vinyl, digital

### For Developers
- **Cleaner separation of concerns** - Musical identity vs publication vs files
- **MusicBrainz alignment** - Future integration with MusicBrainz easier
- **Better normalization** - No more duplicate artist/album strings
- **Flexible file management** - Same recording can have multiple files

### For the Data Model
- **Works and Recordings** - Proper distinction between composition and performance
- **Proper relationships** - Many-to-many where appropriate
- **Extensibility** - Easy to add covers, live versions, remasters
- **Performance** - Indexed for common queries

## Migration Strategy

**No migration required** - The app is in rapid development, and the database can be recreated from scratch:

1. Old database files will be incompatible
2. Users should re-import their music files
3. The new import pipeline will properly populate all entities

## Future Enhancements

With this foundation in place, future features become easier:

- **MusicBrainz integration** - Match and tag using MusicBrainz data
- **Multiple recordings** - Same work performed by different artists
- **Compilation intelligence** - Proper various artists handling
- **Physical media cataloging** - Track what you own physically
- **Re-releases tracking** - Original vs remaster vs deluxe edition
- **Relationship graph** - Cover versions, samples, remixes
- **Advanced search** - By work, recording, artist role, label, etc.

## Entity Relationship Diagram

```
Artist ──(many-to-many via work_artist)── Work
                                            │
                                            │(many-to-many via recording_work)
                                            ├
Artist ──(many-to-many via recording_artist)── Recording ──(many-to-many via recording_digital_file)── DigitalFile
                                                 │
                                                 │(one-to-many)
                                                 ├
                                              Track
                                                 │
                                            (belongs to)
                                                 ├
                                              Medium
                                                 │
                                            (belongs to)
                                                 ├
                                              Release ──(many-to-many via release_label)── Label
                                                 │
                                            (belongs to)
                                                 ├
                                           ReleaseGroup
                                                 │
                                            (belongs to, optional)
                                                 ├
                                              Artist
```

## Files Changed

### New Files
- `MusicPlayer/Models/Work.swift`
- `MusicPlayer/Models/Recording.swift`
- `MusicPlayer/Models/Label.swift`
- `MusicPlayer/Models/Medium.swift`
- `MusicPlayer/Models/ReleaseGroup.swift`

### Modified Files
- `MusicPlayer/Models/Track.swift` - Refactored to reference Recording
- `MusicPlayer/Models/Release.swift` - Refactored to reference ReleaseGroup
- `MusicPlayer/Models/DigitalFile.swift` - Refactored for Recording relationship
- `MusicPlayer/Models/Album.swift` - Converted to view model
- `MusicPlayer/Database/Migrations/01_v1.swift` - Complete schema rewrite
- `MusicPlayer/Repositories/GRDBRecords.swift` - Complete rewrite with new records
- `MusicPlayer/Repositories/GRDBRepository.swift` - Complete rewrite implementing new protocols
- `MusicPlayer/Repositories/MusicRepositories.swift` - Added new repository protocols
- `MusicPlayer/Services/MusicImportService.swift` - Rewritten for new pipeline
- `MusicPlayer/Services/DatabaseService.swift` - Updated to support new API

## Testing Checklist

- [ ] Database creation succeeds
- [ ] Import single audio file
- [ ] Import multiple audio files
- [ ] Works are created and linked to artists
- [ ] Recordings are created and linked to works and artists
- [ ] ReleaseGroups are created properly
- [ ] Releases are created under ReleaseGroups
- [ ] Media are created for each disc
- [ ] Tracks are sequenced correctly on media
- [ ] DigitalFiles are linked to recordings
- [ ] Albums view still works (UI compatibility)
- [ ] Artists view still works
- [ ] Tracks can be played via their recordings
- [ ] Collections still work

## Known Limitations

1. **No UI for new entities yet** - Works, Recordings, Labels, Media not exposed in UI
2. **Heuristic matching** - Work and Recording upserts use simple title matching
3. **No MusicBrainz IDs** - Future enhancement to add MBID columns
4. **Genre removed from Track** - Will be added to Work or Recording in future
5. **Composer tracking** - Need to decide: Work or Recording level?

## Notes for Developers

- The `Album` model is now a **view model only** - don't try to persist it
- Always use `ReleaseGroup` when working with the repository layer
- Tracks no longer contain metadata - access it via `track.recording?.title` etc.
- The import service handles all entity creation - don't create entities manually
- Use the repository protocols, not the concrete GRDBRepository class
