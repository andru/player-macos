import SwiftUI

struct QueueView: View {
    @EnvironmentObject var container: AppContainer
    
    var body: some View {
        let audioPlayer = container.audioPlayer
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Queue")
                    .font(.title2)
                    .bold()
                
                Spacer()
                
                if !audioPlayer.queue.isEmpty {
                    Button(action: { audioPlayer.clearQueue() }) {
                        Text("Clear")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            
            Divider()
            
            // Queue list
            if audioPlayer.queue.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No songs in queue")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Play an album or song to see it here")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(audioPlayer.queue.enumerated()), id: \.element.id) { index, item in
                                QueueItemView(
                                    item: item,
                                    index: index,
                                    isCurrentTrack: index == audioPlayer.currentQueueIndex,
                                    onTap: {
                                        audioPlayer.currentQueueIndex = index
                                        try? audioPlayer.play(track: item.track)
                                        
                                    }
                                )
//                                .onDrag {
//                                    return NSItemProvider(object: String(index) as NSString)
//                                }
//                                .onDrop(of: [.text], delegate: QueueDropDelegate(
//                                    item: index,
//                                    items: audioPlayer.queue,
//                                    currentIndex: audioPlayer.currentQueueIndex,
//                                    audioPlayer: audioPlayer
//                                ))
                            }
                        }
                    }
                    .onAppear {
                        if audioPlayer.currentQueueIndex >= 0 && audioPlayer.currentQueueIndex < audioPlayer.queue.count {
                            proxy.scrollTo(audioPlayer.queue[audioPlayer.currentQueueIndex].id, anchor: .center)
                        }
                    }
                }
            }
        }
        .frame(minWidth: 300, maxWidth: 350)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

struct QueueItemView: View {
    let item: QueueItem
    let index: Int
    let isCurrentTrack: Bool
    let onTap: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Track number or play indicator
                if isCurrentTrack {
                    Image(systemName: "play.fill")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                        .frame(width: 20)
                } else {
                    Text("\(index + 1)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                }
                
                // Album artwork
                if let artwork = item.track.artworkData {
                    Image(nsImage: NSImage(data: artwork) ?? NSImage())
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .cornerRadius(4)
                        .clipped()
                } else {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        )
                }
                
                // Track info
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.track.title)
                        .font(.subheadline)
                        .lineLimit(1)
                        .foregroundColor(item.hasBeenPlayed ? .secondary : .primary)
                    
                    Text(item.track.artist)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .opacity(item.hasBeenPlayed ? 0.5 : 1.0)
                
                Spacer()
                
                // Duration
                Text(item.track.formattedDuration)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Group {
                    if isCurrentTrack {
                        Color.accentColor.opacity(0.2)
                    } else if isHovered {
                        Color.accentColor.opacity(0.1)
                    } else {
                        Color.clear
                    }
                }
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct QueueDropDelegate: DropDelegate {
    let item: Int
    @Binding var items: [QueueItem]
    @Binding var currentIndex: Int
    let audioPlayer: AudioPlayerService
    
    func performDrop(info: DropInfo) -> Bool {
        // Return success only if we have valid item providers
        return !info.itemProviders(for: [.text]).isEmpty
    }
    
    func dropEntered(info: DropInfo) {
        guard let itemProviders = info.itemProviders(for: [.text]).first else { return }
        
        itemProviders.loadItem(forTypeIdentifier: "public.text", options: nil) { (data, error) in
            if let data = data as? Data,
               let sourceIndexString = String(data: data, encoding: .utf8),
               let sourceIndex = Int(sourceIndexString) {
                DispatchQueue.main.async {
                    if sourceIndex != item {
                        audioPlayer.moveQueueItem(from: sourceIndex, to: item)
                    }
                }
            }
        }
    }
}
