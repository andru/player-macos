import SwiftUI

struct AlbumContextMenu: View {
    let album: Album
    let audioPlayer: AudioPlayer
    let library: LibraryService?
    
    var body: some View {
        Button("Play Now") {
            audioPlayer.queueTracks(album.tracks, startPlaying: true)
        }
        
        Button("Next in Queue") {
            audioPlayer.addToQueueNext(album.tracks)
        }
        
        Button("End of Queue") {
            audioPlayer.addToQueueEnd(album.tracks)
        }
        
        Divider()
        
        Button("Favourite") {
            album.tracks.forEach { library?.toggleFavorite(track: $0) }
        }
        
        Button("Add to Collection") {
            // TODO: Show collection picker
            print("Add to collection")
        }
        
        Button("Add to Playlist") {
            // TODO: Show playlist picker
            print("Add to playlist")
        }
        
        Divider()
        
        Button("Remove from Library") {
            album.tracks.forEach { library?.removeFromLibrary(track: $0) }
        }
        
        Button("Refresh from Source") {
            album.tracks.forEach { library?.refreshFromSource(track: $0) }
        }
        
        Button("Edit Info") {
            // Edit first track or album info
            if let firstTrack = album.tracks.first {
                library?.editInfo(track: firstTrack)
            }
        }
    }
}
