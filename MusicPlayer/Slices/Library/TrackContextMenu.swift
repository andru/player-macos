import SwiftUI

struct TrackContextMenu: View {
    @EnvironmentObject var container: AppContainer
    let track: Track
    
    var body: some View {
        let audioPlayer = container.library.audioPlayer
        Button("Play Now") {
            audioPlayer.playNow(track)
        }
        
        Button("Next in Queue") {
            audioPlayer.addToQueueNext(track)
        }
        
        Button("End of Queue") {
            audioPlayer.addToQueueEnd(track)
        }
        
        Divider()
        
        Button("Favourite") {
//            library?.toggleFavorite(track: track)
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
//            library?.removeFromLibrary(track: track)
        }
        
        Button("Refresh from Source") {
//            library?.refreshFromSource(track: track)
        }
        
        Button("Edit Info") {
//            library?.editInfo(track: track)
        }
    }
}

