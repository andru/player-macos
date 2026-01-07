import GRDB

extension DatabaseMigrator {
    mutating func registerV1() {
        registerMigration("v1") { db in
            // Create tracks table
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
            
            // Create collections table
            try db.create(table: "collections") { t in
                t.column("id", .text).primaryKey()
                t.column("name", .text).notNull()
            }
            
            // Create collection_tracks junction table
            try db.create(table: "collection_tracks") { t in
                t.column("collectionId", .text).notNull()
                t.column("trackId", .text).notNull()
                t.column("position", .integer).notNull()
                t.primaryKey(["collectionId", "trackId"])
                t.foreignKey(["collectionId"], references: "collections", columns: ["id"], onDelete: .cascade)
                t.foreignKey(["trackId"], references: "tracks", columns: ["id"], onDelete: .cascade)
            }
            
            // Create indexes for better performance
            try db.create(index: "idx_tracks_artist", on: "tracks", columns: ["artist"])
            try db.create(index: "idx_tracks_album", on: "tracks", columns: ["album"])
            try db.create(index: "idx_tracks_album_artist", on: "tracks", columns: ["albumArtist"])
            try db.create(index: "idx_collection_tracks_collection", on: "collection_tracks", columns: ["collectionId"])
        }
    }
}
