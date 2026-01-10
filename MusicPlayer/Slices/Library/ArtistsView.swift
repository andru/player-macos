import SwiftUI

struct ArtistsView: View {
    let vm: LibraryViewModel
    
    var body: some View {
        ScrollView {
            VStack {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16)], spacing: 16) {
                    ForEach(vm.artistRows) { artistRow in
                        ArtistGridItem(artistRow: artistRow) {
                            //                        let allTracks = artist.albums.flatMap { $0.tracks }
                            //                        audioPlayer.queueTracks(allTracks, startPlaying: true, behavior: preferences.playbackBehavior)
                        }
                    }
                }
            }.padding()
        }
    }
}


struct ArtistGridItem: View {
    let artistRow: ArtistRow
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: action) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                    )
            }
            .buttonStyle(.plain)
            
//            VStack(alignment: .leading, spacing: 2) {
//                Text(artist.name)
//                    .font(.headline)
//                    .lineLimit(1)
//                
//                Text("\(artist.albums.count) albums • \(artist.trackCount) songs")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//                    .lineLimit(1)
//            }
        }
    }
}
