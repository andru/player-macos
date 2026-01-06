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
            if let track = audioPlayer.currentTrack {
                HStack(spacing: 12) {
                    // Album artwork
                    if let artwork = track.artwork {
                        Image(nsImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .cornerRadius(4)
                            .clipped()
                    } else {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "music.note")
                                    .foregroundColor(.secondary)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title)
                            .font(.headline)
                            .lineLimit(1)
                        
                        Text("\(track.artist) • \(track.album)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Time display and scrubber
                    VStack(spacing: 4) {
                        ProgressView(value: audioPlayer.currentTime, total: audioPlayer.duration)
                            .progressViewStyle(.linear)
                            .frame(width: 200)
                        
                        HStack {
                            Text(formatTime(audioPlayer.currentTime))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatTime(audioPlayer.duration))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 200)
                    }
                }
                .frame(maxWidth: 500)
            } else {
                Spacer()
            }
            
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
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
