import SwiftUI

@MainActor
class SongsViewModel: ObservableObject {
    @Published var sortOrder = [KeyPathComparator(\Track.title)]
    
}
