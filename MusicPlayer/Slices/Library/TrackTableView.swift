import SwiftUI

struct TrackTableView: View {
    @EnvironmentObject var library: LibraryManager
    @EnvironmentObject var preferences: PreferencesService
    var filteredTracks: [Track]
    let audioPlayer: AudioPlayer
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("#")
                    .frame(width: 40)
                Text("Title")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Artist")
                    .frame(width: 200, alignment: .leading)
                Text("Album")
                    .frame(width: 200, alignment: .leading)
                Text("Duration")
                    .frame(width: 80, alignment: .trailing)
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // Rows
            ForEach(Array(filteredTracks.enumerated()), id: \.element.id) { index, track in
                
                TrackTableRow(track: track, index: index + 1, action: {
                    audioPlayer.queueTracks([track], startPlaying: true, behavior: preferences.playbackBehavior)
                }, audioPlayer: audioPlayer, library: library)
                
            }
        }
    }
}


struct TrackTableRow: View {
    let track: Track
    let index: Int
    let action: () -> Void
    let audioPlayer: AudioPlayer?
    let library: LibraryManager?
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text("\(index)")
                    .frame(width: 40)
                    .foregroundColor(.secondary)
                
                Text(track.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(track.artist)
                    .frame(width: 200, alignment: .leading)
                    .foregroundColor(.secondary)
                
                Text(track.album)
                    .frame(width: 200, alignment: .leading)
                    .foregroundColor(.secondary)
                
                Text(track.formattedDuration)
                    .frame(width: 80, alignment: .trailing)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            if let audioPlayer = audioPlayer {
                TrackContextMenu(track: track, audioPlayer: audioPlayer, library: library)
            }
        }
        .onHover { hovering in
            isHovered = hovering
        }
        
        Divider()
    }
}
