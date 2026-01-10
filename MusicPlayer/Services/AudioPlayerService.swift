import Foundation
import AVFoundation
import Combine

// MARK: - PlayerState

/// Decoupled playback state for optimal SwiftUI performance.
/// Only views that need playback state should observe this object.
class PlayerState: ObservableObject {
    @Published var currentTrack: PlayerMedia?
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
}

// MARK: - AudioPlayer

class AudioPlayerService: NSObject, ObservableObject {
    @Published var queue: [QueueItem] = []
    @Published var currentQueueIndex: Int = -1
    
    let playerState = PlayerState()
    
    private var player: AVAudioPlayer?
    private var timer: Timer?
    private var lastPublishedTime: Date = Date()
    private let timeUpdateThrottle: TimeInterval = 0.5 // Update every 0.5s instead of 0.1s
    
    func play(track: PlayerMedia) throws {
        // Stop current playback
        stop()
        
        do {
            // Safely unwrap recording and its first digital file. Return nil if not available.
            guard let fileURL = track.fileURL else {
                return
            }
            // Create and configure audio player
            player = try AVAudioPlayer(contentsOf: fileURL)
            player?.prepareToPlay()
//            player?.delegate = self
            
            playerState.currentTrack = track
            playerState.duration = player?.duration ?? 0
            
            // Start playback
            player?.play()
            playerState.isPlaying = true
            
            // Start timer to update current time
            startTimer()
            
            // Mark current track as being played (not completed yet)
            if currentQueueIndex >= 0 && currentQueueIndex < queue.count {
                queue[currentQueueIndex].hasBeenPlayed = false
            }
        } catch {
            print("Error playing track: \(error.localizedDescription)")
        }
    }
    
    func pause() {
        player?.pause()
        playerState.isPlaying = false
        stopTimer()
    }
    
    func resume() {
        player?.play()
        playerState.isPlaying = true
        startTimer()
    }
    
    func stop() {
        player?.stop()
        player = nil
        playerState.isPlaying = false
        playerState.currentTime = 0
        stopTimer()
    }
    
    func seek(to time: TimeInterval) {
        player?.currentTime = time
        playerState.currentTime = time
        // Reset timestamp after publishing to ensure accurate throttling
        lastPublishedTime = Date()
    }
    
    func skipForward() {
        let newTime = min(playerState.currentTime + 10, playerState.duration)
        seek(to: newTime)
    }
    
    func skipBackward() {
        let newTime = max(playerState.currentTime - 10, 0)
        seek(to: newTime)
    }
    
    private func startTimer() {
        // Update every 0.1s but throttle published updates using timestamp
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.player else { return }
            
            // Throttle updates based on time elapsed since last publish
            let now = Date()
            if now.timeIntervalSince(self.lastPublishedTime) >= self.timeUpdateThrottle {
                self.playerState.currentTime = player.currentTime
                self.lastPublishedTime = now
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Queue Management
    
    func queueTracks(_ tracks: [PlayerMedia], startPlaying: Bool = true, behavior: PlaybackBehavior = .clearAndPlay) {
        switch behavior {
        case .clearAndPlay:
            // Clear queue and replace with new tracks
            queue = tracks.map { QueueItem(track: $0, hasBeenPlayed: false) }
            currentQueueIndex = 0
            if startPlaying {
                try? play(track: tracks[0])
            }
        case .appendToQueue:
            // Append to end of queue
            tracks.forEach { addToQueue($0) }
            // If nothing is currently queued (currentQueueIndex == -1) and startPlaying is true, start playing
            // Note: We don't start playing if currentQueueIndex >= 0, even if paused, to respect user's state
            if startPlaying && currentQueueIndex == -1 && !queue.isEmpty {
                currentQueueIndex = 0
                try? play(track: queue[0].track)
            }
        }
    }
    
    func addToQueue(_ track: PlayerMedia) {
        queue.append(QueueItem(track: track, hasBeenPlayed: false))
    }
    
    func addToQueueNext(_ track: PlayerMedia) {
        if queue.isEmpty || currentQueueIndex == -1 {
            // If queue is empty, just add to queue and start playing
            queue.append(QueueItem(track: track, hasBeenPlayed: false))
        } else {
            let insertIndex = currentQueueIndex + 1
            queue.insert(QueueItem(track: track, hasBeenPlayed: false), at: insertIndex)
        }
    }
    
    func addToQueueNext(_ tracks: [PlayerMedia]) {
        if queue.isEmpty || currentQueueIndex == -1 {
            // If queue is empty, just add to queue
            queue.append(contentsOf: tracks.map { QueueItem(track: $0, hasBeenPlayed: false) })
        } else {
            let insertIndex = currentQueueIndex + 1
            let queueItems = tracks.map { QueueItem(track: $0, hasBeenPlayed: false) }
            queue.insert(contentsOf: queueItems, at: insertIndex)
        }
    }
    
    func addToQueueEnd(_ track: PlayerMedia) {
        queue.append(QueueItem(track: track, hasBeenPlayed: false))
    }
    
    func addToQueueEnd(_ tracks: [PlayerMedia]) {
        queue.append(contentsOf: tracks.map { QueueItem(track: $0, hasBeenPlayed: false) })
    }
    
    func playNow(_ track: PlayerMedia) {
        if queue.isEmpty || currentQueueIndex == -1 {
            // If queue is empty, create new queue with this track and play it
            queue = [QueueItem(track: track, hasBeenPlayed: false)]
            currentQueueIndex = 0
            try? play(track: track)
        } else {
            // Add track to queue after current position and play it immediately
            addToQueueNext(track)
            currentQueueIndex += 1
            try? play(track: track)
        }
    }
    
    func clearQueue() {
        queue.removeAll()
        currentQueueIndex = -1
    }
    
    func playNext() {
        guard !queue.isEmpty else { return }
        
        let nextIndex = currentQueueIndex + 1
        if nextIndex < queue.count {
            currentQueueIndex = nextIndex
            try? play(track: queue[nextIndex].track)
        }
    }
    
    func playPrevious() {
        guard !queue.isEmpty else { return }
        
        let previousIndex = currentQueueIndex - 1
        if previousIndex >= 0 {
            currentQueueIndex = previousIndex
            // Reset played state since we're playing this track again
            queue[previousIndex].hasBeenPlayed = false
            try? play(track: queue[previousIndex].track)
        }
    }
    
    func moveQueueItem(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex else { return }
        guard sourceIndex >= 0 && sourceIndex < queue.count else { return }
        guard destinationIndex >= 0 && destinationIndex < queue.count else { return }
        
        let item = queue.remove(at: sourceIndex)
        queue.insert(item, at: destinationIndex)
        
        // Update current index if necessary
        if sourceIndex == currentQueueIndex {
            currentQueueIndex = destinationIndex
        } else if sourceIndex < currentQueueIndex && destinationIndex >= currentQueueIndex {
            currentQueueIndex -= 1
        } else if sourceIndex > currentQueueIndex && destinationIndex <= currentQueueIndex {
            currentQueueIndex += 1
        }
    }
}

// MARK: - Queue Item Model

struct QueueItem: Identifiable {
    let id = UUID()
    let track: PlayerMedia
    var hasBeenPlayed: Bool
}

extension AudioPlayerService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playerState.isPlaying = false
        playerState.currentTime = 0
        stopTimer()
        
        if !flag {
            print("Audio playback did not complete successfully")
        }
        
        // Mark current track as played and advance to next
        if currentQueueIndex >= 0 && currentQueueIndex < queue.count {
            queue[currentQueueIndex].hasBeenPlayed = true
        }
        
        // Auto-advance to next track in queue
        if currentQueueIndex + 1 < queue.count {
            playNext()
        }
    }
}

class AudioPlayerServiceError: LocalizedError {
    private var message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? {
        return message
    }
}
