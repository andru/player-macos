import SwiftUI

struct NowPlayingWidget: View {
    @ObservedObject var playerState: PlayerState
    var onSeek: (TimeInterval) -> Void
    
    var body: some View {
        if let track = playerState.currentTrack {
            HStack(spacing: 12) {
                // Album artwork placeholder
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
                    
                    Text("\(track.artistName) • \(track.release?.album?.title ?? "Unknown Album")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Time display and seekable scrubber
                VStack(spacing: 4) {
                    // Custom seekable slider with expanded click zone
                    GeometryReader { geometry in
                        ZStack(alignment: .center) {
                            // Expanded clickable area (invisible)
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 20)
                            
                            // Visual progress bar
                            ZStack(alignment: .leading) {
                                // Background track
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 4)
                                    .cornerRadius(2)
                                
                                // Progress fill
                                Rectangle()
                                    .fill(Color.accentColor)
                                    .frame(width: progressWidth(for: geometry.size.width), height: 4)
                                    .cornerRadius(2)
                            }
                            .frame(height: 4)
                        }
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    handleSeek(at: value.location.x, width: geometry.size.width)
                                }
                                .onEnded { value in
                                    handleSeek(at: value.location.x, width: geometry.size.width)
                                }
                        )
                    }
                    .frame(width: 200, height: 20)
                    
                    HStack {
                        Text(formatTime(playerState.currentTime))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatTime(playerState.duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 200)
                }
            }
            .frame(maxWidth: 500)
        }
    }
    
    private func progressWidth(for totalWidth: CGFloat) -> CGFloat {
        guard playerState.duration > 0 else { return 0 }
        return totalWidth * CGFloat(playerState.currentTime / playerState.duration)
    }
    
    private func handleSeek(at x: CGFloat, width: CGFloat) {
        let percentage = max(0, min(1, x / width))
        let newTime = playerState.duration * Double(percentage)
        onSeek(newTime)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
