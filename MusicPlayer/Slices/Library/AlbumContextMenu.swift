import SwiftUI

struct AlbumContextMenu: View {
    @EnvironmentObject var container: AppContainer
    let album: Album
    
//    private var allTracks: [Track] {
//        album.releases.flatMap { $0.tracks }
//    }
    
    var body: some View {
        Button("Play Now") {
//            audioPlayer.queueTracks(allTracks, startPlaying: true)
        }
        
        Button("Next in Queue") {
//            audioPlayer.addToQueueNext(allTracks)
        }
        
        Button("End of Queue") {
//            audioPlayer.addToQueueEnd(allTracks)
        }
        
        Divider()
        
        Button("Favourite") {
//            allTracks.forEach {
                //                library?.toggleFavorite(track: $0)
//            }
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
//            allTracks.forEach {
//                library?.removeFromLibrary(track: $0)
//            }
        }
        
        Button("Refresh from Source") {
//            allTracks.forEach {
//                library?.refreshFromSource(track: $0)
//            }
        }
        
        Button("Edit Info") {
            // Edit first track or album info
//            if let firstTrack = allTracks.first {
//                library?.editInfo(track: firstTrack)
//            }
        }
    }
}
