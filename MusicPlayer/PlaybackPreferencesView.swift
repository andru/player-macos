import SwiftUI

struct PlaybackPreferencesView: View {
    @ObservedObject var preferences: PreferencesManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Playback")
                .font(.title2)
                .bold()
            
            Divider()
            
            // Playback Behavior Section
            VStack(alignment: .leading, spacing: 12) {
                Text("When playing a song or album:")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(PlaybackBehavior.allCases, id: \.self) { behavior in
                        HStack(spacing: 8) {
                            Button(action: {
                                preferences.playbackBehavior = behavior
                            }) {
                                Image(systemName: preferences.playbackBehavior == behavior ? "largecircle.fill.circle" : "circle")
                                    .foregroundColor(preferences.playbackBehavior == behavior ? .accentColor : .secondary)
                            }
                            .buttonStyle(.plain)
                            
                            Text(behavior.rawValue)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 500, height: 300)
    }
}
