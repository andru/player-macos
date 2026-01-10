import GRDB

extension DatabaseMigrator {
    mutating func registerV1() {
        registerMigration("v1") { db in
            // Create Artists table
            try db.create(table: "artists") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull()
                t.column("sortName", .text)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }
            
            // Create Works table
            try db.create(table: "works") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("title", .text).notNull()
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }
            
            // Create Recordings table
            try db.create(table: "recordings") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("title", .text).notNull()
                t.column("duration", .double)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }
            
            // Create Labels table
            try db.create(table: "labels") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull()
                t.column("sortName", .text)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }
            
            // Create ReleaseGroups table (album concept)
            try db.create(table: "release_groups") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("title", .text).notNull()
                t.column("primaryArtistId", .integer)
                    .references("artists", onDelete: .setNull)
                t.column("isCompilation", .boolean).notNull().defaults(to: false)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }
            
            // Create Releases table
            try db.create(table: "releases") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("releaseGroupId", .integer).notNull()
                    .references("release_groups", onDelete: .cascade)
                t.column("format", .text).notNull() // CD, Vinyl, Tape, Digital, Other
                t.column("edition", .text)
                t.column("year", .integer)
                t.column("country", .text)
                t.column("catalogNumber", .text)
                t.column("barcode", .text)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }
            
            // Create Media table (disc/side within a release)
            try db.create(table: "media") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("releaseId", .integer).notNull()
                    .references("releases", onDelete: .cascade)
                t.column("position", .integer).notNull().defaults(to: 1)
                t.column("format", .text)
                t.column("title", .text)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }
            
            // Create Tracks table (recording sequenced on medium)
            try db.create(table: "tracks") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("mediumId", .integer).notNull()
                    .references("media", onDelete: .cascade)
                t.column("recordingId", .integer).notNull()
                    .references("recordings", onDelete: .cascade)
                t.column("position", .integer).notNull()
                t.column("titleOverride", .text)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }
            
            // Create DigitalFiles table
            try db.create(table: "digital_files") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("fileURL", .text).notNull()
                t.column("bookmarkData", .blob)
                t.column("fileHash", .text)
                t.column("fileSize", .integer)
                t.column("addedAt", .datetime).notNull()
                t.column("lastScannedAt", .datetime)
                t.column("metadataJSON", .text)
                t.column("artworkData", .blob)
            }
            
            // Create join table: work_artist
            try db.create(table: "work_artist") { t in
                t.column("workId", .integer).notNull()
                    .references("works", onDelete: .cascade)
                t.column("artistId", .integer).notNull()
                    .references("artists", onDelete: .cascade)
                t.column("role", .text)
                t.primaryKey(["workId", "artistId"])
            }
            
            // Create join table: recording_work
            try db.create(table: "recording_work") { t in
                t.column("recordingId", .integer).notNull()
                    .references("recordings", onDelete: .cascade)
                t.column("workId", .integer).notNull()
                    .references("works", onDelete: .cascade)
                t.primaryKey(["recordingId", "workId"])
            }
            
            // Create join table: recording_artist
            try db.create(table: "recording_artist") { t in
                t.column("recordingId", .integer).notNull()
                    .references("recordings", onDelete: .cascade)
                t.column("artistId", .integer).notNull()
                    .references("artists", onDelete: .cascade)
                t.column("role", .text)
                t.primaryKey(["recordingId", "artistId"])
            }
            
            // Create join table: release_label
            try db.create(table: "release_label") { t in
                t.column("releaseId", .integer).notNull()
                    .references("releases", onDelete: .cascade)
                t.column("labelId", .integer).notNull()
                    .references("labels", onDelete: .cascade)
                t.column("catalogNumber", .text)
                t.primaryKey(["releaseId", "labelId"])
            }
            
            // Create join table: recording_digital_file
            try db.create(table: "recording_digital_file") { t in
                t.column("recordingId", .integer).notNull()
                    .references("recordings", onDelete: .cascade)
                t.column("digitalFileId", .integer).notNull()
                    .references("digital_files", onDelete: .cascade)
                t.primaryKey(["recordingId", "digitalFileId"])
            }
            
            // Create LocalTrack table (audio files on disk)
            try db.create(table: "local_tracks") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("fileURL", .text).notNull()
                t.column("bookmarkData", .blob)
                t.column("contentHash", .text).notNull()
                t.column("fileSize", .integer)
                t.column("mtime", .datetime)
                t.column("duration", .double)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }
            
            // Create LocalTrackTags table (tags from audio files)
            try db.create(table: "local_track_tags") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("localTrackId", .integer).notNull()
                    .references("local_tracks", onDelete: .cascade)
                t.column("title", .text)
                t.column("artist", .text)
                t.column("album", .text)
                t.column("albumArtist", .text)
                t.column("composer", .text)
                t.column("trackNumber", .integer)
                t.column("discNumber", .integer)
                t.column("year", .integer)
                t.column("isCompilation", .boolean).notNull().defaults(to: false)
                t.column("genre", .text)
                t.column("recordingMBID", .text)
                t.column("releaseMBID", .text)
                t.column("releaseGroupMBID", .text)
                t.column("artistMBID", .text)
                t.column("workMBID", .text)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }
            
            // Create LibraryTrack table (playable tracks)
            try db.create(table: "library_tracks") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("localTrackId", .integer).notNull()
                    .references("local_tracks", onDelete: .cascade)
                t.column("localTrackTagsId", .integer).notNull()
                    .references("local_track_tags", onDelete: .cascade)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }
            
            // Create TrackMatch table (library track to recording linkage)
            try db.create(table: "track_matches") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("libraryTrackId", .integer).notNull()
                    .references("library_tracks", onDelete: .cascade)
                t.column("recordingId", .integer).notNull()
                    .references("recordings", onDelete: .cascade)
                t.column("confidence", .double).notNull()
                t.column("matchedAt", .datetime).notNull()
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
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
            try db.create(index: "idx_works_title", on: "works", columns: ["title"])
            try db.create(index: "idx_recordings_title", on: "recordings", columns: ["title"])
            try db.create(index: "idx_labels_name", on: "labels", columns: ["name"])
            try db.create(index: "idx_release_groups_title", on: "release_groups", columns: ["title"])
            try db.create(index: "idx_release_groups_artist", on: "release_groups", columns: ["primaryArtistId"])
            try db.create(index: "idx_releases_group", on: "releases", columns: ["releaseGroupId"])
            try db.create(index: "idx_releases_format", on: "releases", columns: ["format"])
            try db.create(index: "idx_media_release", on: "media", columns: ["releaseId"])
            try db.create(index: "idx_tracks_medium", on: "tracks", columns: ["mediumId"])
            try db.create(index: "idx_tracks_recording", on: "tracks", columns: ["recordingId"])
            try db.create(index: "idx_digital_files_url", on: "digital_files", columns: ["fileURL"])
            try db.create(index: "idx_work_artist_work", on: "work_artist", columns: ["workId"])
            try db.create(index: "idx_work_artist_artist", on: "work_artist", columns: ["artistId"])
            try db.create(index: "idx_recording_work_recording", on: "recording_work", columns: ["recordingId"])
            try db.create(index: "idx_recording_work_work", on: "recording_work", columns: ["workId"])
            try db.create(index: "idx_recording_artist_recording", on: "recording_artist", columns: ["recordingId"])
            try db.create(index: "idx_recording_artist_artist", on: "recording_artist", columns: ["artistId"])
            try db.create(index: "idx_release_label_release", on: "release_label", columns: ["releaseId"])
            try db.create(index: "idx_release_label_label", on: "release_label", columns: ["labelId"])
            try db.create(index: "idx_recording_digital_file_recording", on: "recording_digital_file", columns: ["recordingId"])
            try db.create(index: "idx_recording_digital_file_file", on: "recording_digital_file", columns: ["digitalFileId"])
            
            // Indexes for new bridge tables
            try db.create(index: "idx_local_tracks_content_hash", on: "local_tracks", columns: ["contentHash"])
            try db.create(index: "idx_local_tracks_file_url", on: "local_tracks", columns: ["fileURL"])
            try db.create(index: "idx_local_track_tags_local_track", on: "local_track_tags", columns: ["localTrackId"])
            try db.create(index: "idx_local_track_tags_title", on: "local_track_tags", columns: ["title"])
            try db.create(index: "idx_local_track_tags_artist", on: "local_track_tags", columns: ["artist"])
            try db.create(index: "idx_local_track_tags_album", on: "local_track_tags", columns: ["album"])
            try db.create(index: "idx_local_track_tags_album_artist", on: "local_track_tags", columns: ["albumArtist"])
            try db.create(index: "idx_local_track_tags_composer", on: "local_track_tags", columns: ["composer"])
            try db.create(index: "idx_library_tracks_local_track", on: "library_tracks", columns: ["localTrackId"])
            try db.create(index: "idx_library_tracks_tags", on: "library_tracks", columns: ["localTrackTagsId"])
            try db.create(index: "idx_track_matches_library_track", on: "track_matches", columns: ["libraryTrackId"])
            try db.create(index: "idx_track_matches_recording", on: "track_matches", columns: ["recordingId"])
        }
    }
}
