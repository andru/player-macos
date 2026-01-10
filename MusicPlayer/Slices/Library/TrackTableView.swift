import SwiftUI

// MARK: - Track Table View

struct TrackTableView: View {
    @EnvironmentObject var preferences: PreferencesService
    @ObservedObject var vm: LibraryViewModel
    
    // State for selection
    @State private var selection = Set<Track.ID>()
    
    var body: some View {
        Table(vm.songRows, selection: $selection, sortOrder: Binding(get: { vm.sortOrder }, set: { vm.sortOrder = $0 })) {
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
            TableColumn("Title", value: \.title) { songRow in
                Text(songRow.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .width(min: 100)
            
            // Artist column (sortable)
            TableColumn("Artist", value: \.artistName) { songRow in
                Text(songRow.artistName)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .width(min: 100, ideal: 200)
            
            // Album column (sortable by release album title)
            TableColumn("Album") { songRow in
                Text(songRow.albumTitle)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .width(min: 100, ideal: 200)
            
            // Duration column (sortable)
            TableColumn("Duration") { songRow in
                Text(songRow.duration?.formatted() ?? "-")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(min: 60, ideal: 80, max: 100)
        }
        .frame(minHeight: 100, maxHeight: .infinity)
        .layoutPriority(1)
//        .contextMenu(forSelectionType: Track.ID.self) { items in
//            // Context menu for selected items
//            if items.count == 1, let trackID = items.first,
//               let track = filteredTracks.first(where: { $0.id == trackID }) {
//                TrackContextMenu(track: track)
//            } else if items.count > 1 {
//                Button("Play Selected") {
//                    let selectedTracks = filteredTracks.filter { items.contains($0.id) }
//                    audioPlayer.queueTracks(selectedTracks, startPlaying: true, behavior: preferences.playbackBehavior)
//                }
//                Button("Add to Queue") {
//                    let selectedTracks = filteredTracks.filter { items.contains($0.id) }
//                    audioPlayer.addToQueueEnd(selectedTracks)
//                }
//            }
//        } primaryAction: { items in
//            // Double-click action (primaryAction is called on double-click)
//            let selectedTracks = filteredTracks.filter { items.contains($0.id) }
//            if !selectedTracks.isEmpty {
//                audioPlayer.queueTracks(selectedTracks, startPlaying: true, behavior: preferences.playbackBehavior)
//            }
//        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PreferencesService())
}
