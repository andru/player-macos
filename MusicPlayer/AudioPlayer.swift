import Foundation
import AVFoundation

class AudioPlayer: NSObject, ObservableObject {
    @Published var currentTrack: Track?
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    
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
}

extension AudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentTime = 0
        stopTimer()
        
        if !flag {
            print("Audio playback did not complete successfully")
        }
    }
}
