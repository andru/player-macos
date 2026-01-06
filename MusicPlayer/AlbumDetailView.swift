import SwiftUI

struct AlbumDetailView: View {
    let album: Album
    @ObservedObject var audioPlayer: AudioPlayer
    let onBack: () -> Void
    
    @State private var selectedTrackIDs: Set<UUID> = []
    @State private var lastSelectedTrackID: UUID?
    
    var body: some View {
        VStack(spacing: 0) {
            // Top section with album info
            HStack(alignment: .top, spacing: 24) {
                // Album artwork with play button
                ZStack(alignment: .bottomTrailing) {
                    if let artwork = album.artwork {
                        Image(nsImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 250, height: 250)
                            .cornerRadius(12)
                            .clipped()
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 250, height: 250)
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 60))
                                    .foregroundColor(.secondary)
                            )
                    }
                    
                    // Play button overlay
                    Button(action: {
                        audioPlayer.queueTracks(sortedTracks, startPlaying: true)
                    }) {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "play.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .offset(x: 2)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(12)
                }
                
                // Album metadata
                VStack(alignment: .leading, spacing: 12) {
                    Text(album.name)
                        .font(.system(size: 32, weight: .bold))
                    
                    Text(album.albumArtist ?? album.artist)
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        if let year = album.year {
                            Text(String(year))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let genre = album.tracks.first?.genre {
                            Text(genre)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(totalDuration)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 8)
                
                Spacer()
            }
            .padding(32)
            .padding(.top, 16)
            
            Divider()
            
            // Tracks table
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("#")
                        .frame(width: 40, alignment: .leading)
                    Text("Title")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Duration")
                        .frame(width: 80, alignment: .trailing)
                    // Spacer for heart icon column
                    Spacer()
                        .frame(width: 40)
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)
                .padding(.vertical, 8)
                .background(Color(nsColor: .controlBackgroundColor))
                
                Divider()
                
                // Track rows
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(sortedTracks) { track in
                            AlbumTrackRow(
                                track: track,
                                albumArtist: album.albumArtist ?? album.artist,
                                isSelected: selectedTrackIDs.contains(track.id),
                                onSingleClick: { modifiers in
                                    handleTrackSelection(track: track, modifiers: modifiers)
                                },
                                onDoubleClick: {
                                    audioPlayer.queueTracks([track], startPlaying: true)
                                }
                            )
                        }
                    }
                }
            }
        }
        .overlay(alignment: .topLeading) {
            // Back button
            Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .padding(16)
        }
    }
    
    private var sortedTracks: [Track] {
        album.tracks.sorted { (t1, t2) in
            let n1 = t1.trackNumber ?? Int.max
            let n2 = t2.trackNumber ?? Int.max
            return n1 < n2
        }
    }
    
    private var totalDuration: String {
        let total = album.tracks.reduce(0) { $0 + $1.duration }
        let hours = Int(total) / 3600
        let minutes = (Int(total) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func handleTrackSelection(track: Track, modifiers: NSEvent.ModifierFlags) {
        if modifiers.contains(.shift), let lastID = lastSelectedTrackID {
            // Shift-click: select range
            if let startIndex = sortedTracks.firstIndex(where: { $0.id == lastID }),
               let endIndex = sortedTracks.firstIndex(where: { $0.id == track.id }) {
                let range = min(startIndex, endIndex)...max(startIndex, endIndex)
                for index in range {
                    selectedTrackIDs.insert(sortedTracks[index].id)
                }
            }
        } else {
            // Regular click: toggle selection
            if selectedTrackIDs.contains(track.id) {
                selectedTrackIDs.remove(track.id)
            } else {
                selectedTrackIDs.insert(track.id)
            }
            lastSelectedTrackID = track.id
        }
    }
}

struct AlbumTrackRow: View {
    let track: Track
    let albumArtist: String
    let isSelected: Bool
    let onSingleClick: (NSEvent.ModifierFlags) -> Void
    let onDoubleClick: () -> Void
    
    @State private var isHovered = false
    @State private var clickCount = 0
    @State private var clickWorkItem: DispatchWorkItem?
    
    var body: some View {
        HStack {
            if let trackNum = track.trackNumber {
                Text("\(trackNum)")
                    .frame(width: 40, alignment: .leading)
                    .foregroundColor(.secondary)
            } else {
                Text("-")
                    .frame(width: 40, alignment: .leading)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Show artist if different from album artist
                if track.artist != albumArtist {
                    Text(track.artist)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(track.formattedDuration)
                .frame(width: 80, alignment: .trailing)
                .foregroundColor(.secondary)
            
            // Heart icon placeholder
            Image(systemName: "heart")
                .frame(width: 40)
                .foregroundColor(.secondary)
                .opacity(0.5)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.2) : (isHovered ? Color.accentColor.opacity(0.1) : Color.clear))
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .gesture(
            TapGesture(count: 2)
                .onEnded { _ in
                    clickWorkItem?.cancel()
                    clickCount = 0
                    onDoubleClick()
                }
                .exclusively(before: TapGesture(count: 1)
                    .onEnded { _ in
                        clickCount += 1
                        clickWorkItem?.cancel()
                        
                        let workItem = DispatchWorkItem {
                            if clickCount == 1 {
                                if let event = NSApp.currentEvent {
                                    onSingleClick(event.modifierFlags)
                                } else {
                                    onSingleClick([])
                                }
                            }
                            clickCount = 0
                        }
                        clickWorkItem = workItem
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: workItem)
                    }
                )
        )
        
        Divider()
    }
}
