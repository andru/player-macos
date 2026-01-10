import SwiftUI

struct TrackContextMenu: View {
    @EnvironmentObject var container: AppContainer
    let track: SongRow
    
    init(track: SongRow) {
        self.track = track
    }
    
    var body: some View {
        let audioPlayer = container.library.audioPlayer
        Button("Play Now") {
            Task {
                do {
                    let fullTrack = try await container.repositories.track.loadTrack(id: track.id)
                    guard let fullTrack = fullTrack, let playerMedia = fullTrack.toPlayerMedia() else { return }
                    audioPlayer.playNow(playerMedia)
                } catch {
                    print("Failed to load track: \(error)")
                }
            }
        }
        
        Button("Next in Queue") {
            Task {
                do {
                    let fullTrack = try await container.repositories.track.loadTrack(id: track.id)
                    guard let fullTrack = fullTrack, let playerMedia = fullTrack.toPlayerMedia() else { return }
                    audioPlayer.playNow(playerMedia)
                } catch {
                    print("Failed to load track: \(error)")
                }
            }
        }
        
        Button("End of Queue") {
            Task {
                do {
                    let fullTrack = try await container.repositories.track.loadTrack(id: track.id)
                    guard let fullTrack = fullTrack, let playerMedia = fullTrack.toPlayerMedia() else { return }
                    audioPlayer.playNow(playerMedia)
                } catch {
                    print("Failed to load track: \(error)")
                }
            }
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

