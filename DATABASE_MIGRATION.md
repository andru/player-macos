# Database Migration Guide

## Overview

The MusicPlayer application uses GRDB for database persistence with built-in versioned schema migrations.

## Database Location

The database file is located at:
```
~/Music/MusicPlayer.library/Contents/Resources/library.db
```

## Migration System

GRDB provides a built-in migration system using DatabaseMigrator:

- **Automatic Version Tracking**: Migrations are tracked by name
- **Idempotent**: Each migration runs only once
- **Transactional**: All migrations run in a transaction for safety
- **Declarative**: Schema defined using Swift DSL

## Migration Process

### Automatic Migration from JSON

When you first run the updated version of MusicPlayer:

1. The app checks for an existing `library.json` file
2. If found, it automatically imports all tracks and collections into the new SQLite database
3. The original `library.json` file is renamed to `library.json.backup` for safety
4. All future operations use the SQLite database

### Manual Migration

If you need to manually trigger a migration:

1. Delete the `library.db` file
2. Ensure `library.json` exists in the Resources directory
3. Restart the application
4. The migration will run automatically

## Schema Details

### Version 1 Schema

#### tracks table
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

#### collections table
```sql
CREATE TABLE collections (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL
)
```

#### collection_tracks table
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

For optimal query performance, the following indexes are created:

- `idx_tracks_artist` - Index on artist column
- `idx_tracks_album` - Index on album column
- `idx_tracks_album_artist` - Index on album_artist column
- `idx_collection_tracks_collection` - Index on collection_id in junction table

## Adding New Migrations

To add a new schema migration:

1. Open `GRDBRepository.swift`
2. Add a new migration to the migrator:

```swift
migrator.registerMigration("v2") { db in
    // Example: Add a new column
    try db.alter(table: "tracks") { t in
        t.add(column: "playCount", .integer).defaults(to: 0)
    }
}
```

3. Update the documentation to reflect the new schema

### Migration Best Practices

- Give migrations descriptive names (e.g., "add_play_count", "create_playlists_table")
- Migrations run in registration order
- Always use transactions (automatic with GRDB)
- Test migrations with sample data
- Never modify existing migrations after release

## Rollback

If you need to rollback to the JSON-based storage:

1. Locate your `library.json.backup` file
2. Rename it back to `library.json`
3. Delete the `library.db` file
4. Revert to the previous version of the application

**Warning:** Any changes made after migration will be lost if you rollback.

## Testing

Run the database tests to verify migrations and operations:

```bash
xcodebuild test -project MusicPlayer.xcodeproj -scheme MusicPlayer
```

The test suite includes:
- Database initialization tests
- Schema migration tests
- Track CRUD operation tests
- Collection CRUD operation tests
- Transaction and concurrency tests

## Troubleshooting

### Migration Failed

If migration fails:
1. Check the console logs for specific error messages
2. Verify that `library.json.backup` exists
3. Delete `library.db` and try again
4. If problems persist, restore from backup

### Database Corruption

If the database becomes corrupted:
1. Close the application
2. Delete `library.db`
3. Restore from `library.json.backup` if available
4. Restart the application

### Performance Issues

If experiencing slow performance:
1. Compact the database: `VACUUM;`
2. Analyze query patterns: `PRAGMA optimize;`
3. Check index usage with `EXPLAIN QUERY PLAN`

## Benefits of SQLite

The migration to SQLite provides:

1. **Better Performance**: Indexed queries are significantly faster for large libraries
2. **Data Integrity**: Foreign key constraints ensure referential integrity
3. **ACID Compliance**: Transactions ensure data consistency
4. **Scalability**: Handles large libraries (10,000+ tracks) efficiently
5. **Versioned Migrations**: Easy schema evolution over time
6. **Concurrent Access**: Better handling of simultaneous operations

## Future Enhancements

Potential future migrations may include:

- Play count and last played tracking
- Smart playlists with complex queries
- Full-text search capabilities
- Rating system
- Lyrics storage
- Extended metadata fields
