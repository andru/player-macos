import SwiftUI

@MainActor
class SongsViewModel: ObservableObject {
    @Published var sortOrder = [KeyPathComparator(\Track.title)]
    
    func sortedTracks(from tracks: [Track]) -> [Track] {
        return tracks.sorted(using: sortOrder)
    }
}
