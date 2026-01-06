import Foundation
import AVFoundation

class AudioPlayer: NSObject, ObservableObject {
    @Published var currentTrack: Track?
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var queue: [QueueItem] = []
    @Published var currentQueueIndex: Int = -1
    
    private var player: AVAudioPlayer?
    private var timer: Timer?
    
    func play(track: Track) {
        // Stop current playback
        stop()
        
        do {
            // Create and configure audio player
            player = try AVAudioPlayer(contentsOf: track.fileURL)
            player?.prepareToPlay()
            player?.delegate = self
            
            currentTrack = track
            duration = track.duration
            
            // Start playback
            player?.play()
            isPlaying = true
            
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
        isPlaying = false
        stopTimer()
    }
    
    func resume() {
        player?.play()
        isPlaying = true
        startTimer()
    }
    
    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        currentTime = 0
        stopTimer()
    }
    
    func seek(to time: TimeInterval) {
        player?.currentTime = time
        currentTime = time
    }
    
    func skipForward() {
        let newTime = min(currentTime + 10, duration)
        seek(to: newTime)
    }
    
    func skipBackward() {
        let newTime = max(currentTime - 10, 0)
        seek(to: newTime)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.player else { return }
            self.currentTime = player.currentTime
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Queue Management
    
    func queueTracks(_ tracks: [Track], startPlaying: Bool = true, behavior: PlaybackBehavior = .clearAndPlay) {
        if startPlaying {
            switch behavior {
            case .clearAndPlay:
                // Clear queue and play immediately
                queue = tracks.map { QueueItem(track: $0, hasBeenPlayed: false) }
                currentQueueIndex = 0
                play(track: tracks[0])
            case .appendToQueue:
                // Append to end of queue
                tracks.forEach { addToQueue($0) }
                // If nothing is currently playing, start playing
                if currentQueueIndex == -1 && !queue.isEmpty {
                    currentQueueIndex = 0
                    play(track: queue[0].track)
                }
            }
        }
    }
    
    func addToQueue(_ track: Track) {
        queue.append(QueueItem(track: track, hasBeenPlayed: false))
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
            play(track: queue[nextIndex].track)
        }
    }
    
    func playPrevious() {
        guard !queue.isEmpty else { return }
        
        let previousIndex = currentQueueIndex - 1
        if previousIndex >= 0 {
            currentQueueIndex = previousIndex
            // Reset played state since we're playing this track again
            queue[previousIndex].hasBeenPlayed = false
            play(track: queue[previousIndex].track)
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
    let track: Track
    var hasBeenPlayed: Bool
}

extension AudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentTime = 0
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
