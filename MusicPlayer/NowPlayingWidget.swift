import SwiftUI

struct NowPlayingWidget: View {
    @ObservedObject var audioPlayer: AudioPlayer
    
    var body: some View {
        if let track = audioPlayer.currentTrack {
            HStack(spacing: 12) {
                // Album artwork placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(.secondary)
                    )
                
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
                
                // Time display and seekable scrubber
                VStack(spacing: 4) {
                    // Custom seekable slider
                    GeometryReader { geometry in
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
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    handleSeek(at: value.location.x, width: geometry.size.width)
                                }
                        )
                    }
                    .frame(width: 200, height: 4)
                    
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
        }
    }
    
    private func progressWidth(for totalWidth: CGFloat) -> CGFloat {
        guard audioPlayer.duration > 0 else { return 0 }
        return totalWidth * CGFloat(audioPlayer.currentTime / audioPlayer.duration)
    }
    
    private func handleSeek(at x: CGFloat, width: CGFloat) {
        let percentage = max(0, min(1, x / width))
        let newTime = audioPlayer.duration * Double(percentage)
        audioPlayer.seek(to: newTime)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
