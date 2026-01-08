import SwiftUI

// MARK: - Track Table View

struct TrackTableView: View {
    @EnvironmentObject var library: LibraryManager
    @EnvironmentObject var preferences: PreferencesService
    let filteredTracks: [Track]
    let audioPlayer: AudioPlayer
    
    // State for selection and sorting
    @State private var selection = Set<Track.ID>()
    @State private var sortOrder = [KeyPathComparator(\Track.title)]
    
    var body: some View {
        Table(filteredTracks, selection: $selection, sortOrder: $sortOrder) {
            // Track number column (non-sortable)
//            TableColumn("#") { track in
////                if let index = filteredTracks.firstIndex(where: { $0.id == track.id }) {
////                    Text("\(index + 1)")
////                        .foregroundColor(.secondary)
////                        .frame(maxWidth: .infinity, alignment: .leading)
////                }
//                Text("\(track.trackNumber ?? "-")")
//                    
//            }
//            .width(min: 40, ideal: 40, max: 60)
//            
            // Title column (sortable)
            TableColumn("Title", value: \.title) { track in
                Text(track.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .width(min: 100)
            
            // Artist column (sortable)
            TableColumn("Artist", value: \.artist) { track in
                Text(track.artist)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .width(min: 100, ideal: 200)
            
            // Album column (sortable)
            TableColumn("Album", value: \.album) { track in
                Text(track.album)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .width(min: 100, ideal: 200)
            
            // Duration column (sortable)
            TableColumn("Duration", value: \.duration) { track in
                Text(track.formattedDuration)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(min: 60, ideal: 80, max: 100)
        }
        .frame(minHeight: 100, maxHeight: .infinity)
        .layoutPriority(1)
        .contextMenu(forSelectionType: Track.ID.self) { items in
            // Context menu for selected items
            if items.count == 1, let trackID = items.first,
               let track = filteredTracks.first(where: { $0.id == trackID }) {
                TrackContextMenu(track: track, audioPlayer: audioPlayer, library: library)
            } else if items.count > 1 {
                Button("Play Selected") {
                    let selectedTracks = filteredTracks.filter { items.contains($0.id) }
                    audioPlayer.queueTracks(selectedTracks, startPlaying: true, behavior: preferences.playbackBehavior)
                }
                Button("Add to Queue") {
                    let selectedTracks = filteredTracks.filter { items.contains($0.id) }
                    audioPlayer.addToQueueEnd(selectedTracks)
                }
            }
        } primaryAction: { items in
            // Double-click action (primaryAction is called on double-click)
            let selectedTracks = filteredTracks.filter { items.contains($0.id) }
            if !selectedTracks.isEmpty {
                audioPlayer.queueTracks(selectedTracks, startPlaying: true, behavior: preferences.playbackBehavior)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LibraryManager())
        .environmentObject(PreferencesService())
}
