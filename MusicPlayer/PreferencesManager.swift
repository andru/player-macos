import Foundation
import SwiftUI

// MARK: - Playback Behavior
enum PlaybackBehavior: String, CaseIterable {
    case clearAndPlay = "Clear queue and play immediately"
    case appendToQueue = "Append to end of queue"
}

// MARK: - Preferences Manager
@MainActor
class PreferencesManager: ObservableObject {
    @Published var playbackBehavior: PlaybackBehavior {
        didSet {
            UserDefaults.standard.set(playbackBehavior.rawValue, forKey: playbackBehaviorKey)
        }
    }
    
    private let playbackBehaviorKey = "PlaybackBehavior"
    
    init() {
        // Load playback behavior from UserDefaults, default to clearAndPlay
        if let savedBehavior = UserDefaults.standard.string(forKey: playbackBehaviorKey),
           let behavior = PlaybackBehavior.allCases.first(where: { $0.rawValue == savedBehavior }) {
            self.playbackBehavior = behavior
        } else {
            self.playbackBehavior = .clearAndPlay
        }
    }
}
