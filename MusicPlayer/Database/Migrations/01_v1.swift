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
            try db.create(table: "tracks") { t in
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
            
            // Create collections table
            try db.create(table: "collections") { t in
                t.column("id", .text).primaryKey()
                t.column("name", .text).notNull()
            }
            
            // Create collection_tracks junction table
            try db.create(table: "collection_tracks") { t in
                t.column("collectionId", .text).notNull()
                t.column("trackId", .integer).notNull()
                t.column("position", .integer).notNull()
                t.primaryKey(["collectionId", "trackId"])
                t.foreignKey(["collectionId"], references: "collections", columns: ["id"], onDelete: .cascade)
                t.foreignKey(["trackId"], references: "tracks", columns: ["id"], onDelete: .cascade)
            }
            
            // Create indexes for search performance
            try db.create(index: "idx_artists_name", on: "artists", columns: ["name"])
            try db.create(index: "idx_albums_artist_id", on: "albums", columns: ["artistId"])
            try db.create(index: "idx_albums_title", on: "albums", columns: ["title"])
            try db.create(index: "idx_releases_album_id", on: "releases", columns: ["albumId"])
            try db.create(index: "idx_releases_format", on: "releases", columns: ["format"])
            try db.create(index: "idx_tracks_release_id", on: "tracks", columns: ["releaseId"])
            try db.create(index: "idx_tracks_disc_track", on: "tracks", columns: ["discNumber", "trackNumber"])
            try db.create(index: "idx_tracks_title", on: "tracks", columns: ["title"])
            try db.create(index: "idx_tracks_artist_name", on: "tracks", columns: ["artistName"])
            try db.create(index: "idx_tracks_album_artist_name", on: "tracks", columns: ["albumArtistName"])
            try db.create(index: "idx_tracks_composer_name", on: "tracks", columns: ["composerName"])
            try db.create(index: "idx_digital_files_track_id", on: "digital_files", columns: ["trackId"])
            try db.create(index: "idx_digital_files_file_url", on: "digital_files", columns: ["fileURL"])

        }
    }
}
