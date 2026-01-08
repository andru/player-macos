import GRDB

extension DatabaseMigrator {
    mutating func registerV2PhysicalMedia() {
        registerMigration("v2_physical_media") { db in
            // Create Artists table
            try db.create(table: "artists") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull()
                t.column("sortName", .text)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }
            
            // Create Albums table
            try db.create(table: "albums") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("artistId", .integer).notNull()
                    .references("artists", onDelete: .cascade)
                t.column("title", .text).notNull()
                t.column("sortTitle", .text)
                t.column("albumArtistName", .text)
                t.column("composerName", .text)
                t.column("isCompilation", .boolean).notNull().defaults(to: false)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }
            
            // Create Releases table
            try db.create(table: "releases") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("albumId", .integer).notNull()
                    .references("albums", onDelete: .cascade)
                t.column("format", .text).notNull() // CD, Vinyl, Tape, Digital, Other
                t.column("edition", .text)
                t.column("label", .text)
                t.column("year", .integer)
                t.column("country", .text)
                t.column("catalogNumber", .text)
                t.column("barcode", .text)
                t.column("discs", .integer).notNull().defaults(to: 1)
                t.column("releaseTitleOverride", .text)
                t.column("userNotes", .text)
                t.column("isCompilation", .boolean).notNull().defaults(to: false)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }
            
            // Create new Tracks table (will migrate data from old tracks table)
            try db.create(table: "tracks_new") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("releaseId", .integer).notNull()
                    .references("releases", onDelete: .cascade)
                t.column("discNumber", .integer).notNull().defaults(to: 1)
                t.column("trackNumber", .integer)
                t.column("title", .text).notNull()
                t.column("duration", .double)
                t.column("artistName", .text).notNull()
                t.column("albumArtistName", .text)
                t.column("composerName", .text)
                t.column("genre", .text)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }
            
            // Create DigitalFiles table
            try db.create(table: "digital_files") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("trackId", .integer).notNull()
                    .references("tracks_new", onDelete: .cascade)
                t.column("fileURL", .text).notNull()
                t.column("bookmarkData", .blob)
                t.column("fileHash", .text)
                t.column("fileSize", .integer)
                t.column("addedAt", .datetime).notNull()
                t.column("lastScannedAt", .datetime)
                t.column("metadataJSON", .text)
                t.column("artworkData", .blob)
            }
            
            // Create indexes for search performance
            try db.create(index: "idx_artists_name", on: "artists", columns: ["name"])
            try db.create(index: "idx_albums_artist_id", on: "albums", columns: ["artistId"])
            try db.create(index: "idx_albums_title", on: "albums", columns: ["title"])
            try db.create(index: "idx_releases_album_id", on: "releases", columns: ["albumId"])
            try db.create(index: "idx_releases_format", on: "releases", columns: ["format"])
            try db.create(index: "idx_tracks_release_id", on: "tracks_new", columns: ["releaseId"])
            try db.create(index: "idx_tracks_disc_track", on: "tracks_new", columns: ["discNumber", "trackNumber"])
            try db.create(index: "idx_tracks_title", on: "tracks_new", columns: ["title"])
            try db.create(index: "idx_tracks_artist_name", on: "tracks_new", columns: ["artistName"])
            try db.create(index: "idx_tracks_album_artist_name", on: "tracks_new", columns: ["albumArtistName"])
            try db.create(index: "idx_tracks_composer_name", on: "tracks_new", columns: ["composerName"])
            try db.create(index: "idx_digital_files_track_id", on: "digital_files", columns: ["trackId"])
            try db.create(index: "idx_digital_files_file_url", on: "digital_files", columns: ["fileURL"])
            
            // Migrate data from old tracks table
            // For each unique artist -> create artist record
            try db.execute(sql: """
                INSERT INTO artists (name, createdAt, updatedAt)
                SELECT DISTINCT 
                    COALESCE(albumArtist, artist) as name,
                    datetime('now'),
                    datetime('now')
                FROM tracks
                WHERE COALESCE(albumArtist, artist) IS NOT NULL
                ORDER BY name
            """)
            
            // For each unique album -> create album record
            try db.execute(sql: """
                INSERT INTO albums (artistId, title, albumArtistName, isCompilation, createdAt, updatedAt)
                SELECT 
                    (SELECT id FROM artists WHERE name = COALESCE(t.albumArtist, t.artist) LIMIT 1) as artistId,
                    t.album as title,
                    t.albumArtist,
                    0 as isCompilation,
                    datetime('now'),
                    datetime('now')
                FROM (
                    SELECT DISTINCT 
                        album,
                        COALESCE(albumArtist, artist) as albumArtist,
                        artist
                    FROM tracks
                    WHERE album IS NOT NULL
                ) t
            """)
            
            // For each album -> create a default "Digital" release
            try db.execute(sql: """
                INSERT INTO releases (albumId, format, discs, isCompilation, createdAt, updatedAt)
                SELECT 
                    a.id,
                    'Digital' as format,
                    1 as discs,
                    a.isCompilation,
                    datetime('now'),
                    datetime('now')
                FROM albums a
            """)
            
            // Migrate tracks to new table structure
            try db.execute(sql: """
                INSERT INTO tracks_new (
                    releaseId, discNumber, trackNumber, title, duration,
                    artistName, albumArtistName, composerName, genre,
                    createdAt, updatedAt
                )
                SELECT 
                    (
                        SELECT r.id 
                        FROM releases r
                        JOIN albums alb ON alb.id = r.albumId
                        JOIN artists art ON art.id = alb.artistId
                        WHERE alb.title = t.album 
                        AND art.name = COALESCE(t.albumArtist, t.artist)
                        AND r.format = 'Digital'
                        LIMIT 1
                    ) as releaseId,
                    1 as discNumber,
                    t.trackNumber,
                    t.title,
                    t.duration,
                    t.artist as artistName,
                    t.albumArtist as albumArtistName,
                    NULL as composerName,
                    t.genre,
                    datetime('now'),
                    datetime('now')
                FROM tracks t
            """)
            
            // Migrate digital files from old tracks
            try db.execute(sql: """
                INSERT INTO digital_files (
                    trackId, fileURL, addedAt, artworkData
                )
                SELECT 
                    (
                        SELECT tn.id 
                        FROM tracks_new tn
                        JOIN releases r ON r.id = tn.releaseId
                        JOIN albums alb ON alb.id = r.albumId
                        JOIN artists art ON art.id = alb.artistId
                        WHERE tn.title = t.title
                        AND tn.artistName = t.artist
                        AND alb.title = t.album
                        AND art.name = COALESCE(t.albumArtist, t.artist)
                        LIMIT 1
                    ) as trackId,
                    t.fileURL,
                    datetime('now'),
                    t.artworkData
                FROM tracks t
                WHERE t.fileURL IS NOT NULL
            """)
            
            // Drop old tracks table
            try db.drop(table: "tracks")
            
            // Rename new tracks table
            try db.rename(table: "tracks_new", to: "tracks")
        }
    }
}
