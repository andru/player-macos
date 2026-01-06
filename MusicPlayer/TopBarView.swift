import SwiftUI

struct TopBarView: View {
    @ObservedObject var audioPlayer: AudioPlayer
    @Binding var searchText: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Playback controls
            HStack(spacing: 12) {
                Button(action: { audioPlayer.skipBackward() }) {
                    Image(systemName: "backward.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .disabled(audioPlayer.currentTrack == nil)
                
                Button(action: togglePlayPause) {
                    Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title)
                }
                .buttonStyle(.plain)
                .disabled(audioPlayer.currentTrack == nil)
                
                Button(action: { audioPlayer.skipForward() }) {
                    Image(systemName: "forward.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .disabled(audioPlayer.currentTrack == nil)
            }
            .frame(width: 120)
            
            // Current track info
            NowPlayingWidget(audioPlayer: audioPlayer)
            
            Spacer()
            
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
        if audioPlayer.isPlaying {
            audioPlayer.pause()
        } else {
            audioPlayer.resume()
        }
    }
}
