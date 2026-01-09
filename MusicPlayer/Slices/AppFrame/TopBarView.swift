import SwiftUI

struct TopBarView: View {

    @EnvironmentObject var container: AppContainer
    @Binding var searchText: String
    @Binding var showQueue: Bool
    
    var body: some View {
        
        HStack(spacing: 16) {
            // Playback controls
            HStack(spacing: 12) {
                Button(action: { container.appFrame.audioPlayer.playPrevious() }) {
                    Image(systemName: "backward.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .disabled(container.appFrame.audioPlayer.currentQueueIndex <= 0)
                
                Button(action: togglePlayPause) {
                    Image(systemName: container.appFrame.audioPlayer.playerState.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title)
                }
                .buttonStyle(.plain)
                .disabled(container.appFrame.audioPlayer.playerState.currentTrack == nil)
                
                Button(action: { container.appFrame.audioPlayer.playNext() }) {
                    Image(systemName: "forward.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .disabled(container.appFrame.audioPlayer.currentQueueIndex >= container.appFrame.audioPlayer.queue.count - 1)
            }
            .frame(width: 120)
            
            // Current track info
            NowPlayingWidget(playerState: container.appFrame.audioPlayer.playerState, onSeek: { time in
                container.appFrame.audioPlayer.seek(to: time)
            })
            
            Spacer()
            
            // Queue button
            Button(action: { showQueue.toggle() }) {
                Image(systemName: "list.bullet")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            
            // Search box
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search", text: $searchText)
                    .textFieldStyle(.plain)
                    .frame(width: 200)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    private func togglePlayPause() {
        if container.appFrame.audioPlayer.playerState.isPlaying {
            container.appFrame.audioPlayer.pause()
        } else {
            container.appFrame.audioPlayer.resume()
        }
    }
}
