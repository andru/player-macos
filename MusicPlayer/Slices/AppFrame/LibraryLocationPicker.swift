import SwiftUI
import AppKit

struct LibraryLocationPicker: View {
    @ObservedObject var library: AppLibraryService

    var body: some View {
        // Invisible view used solely to present an alert and, when confirmed, open an NSOpenPanel
        Color.clear
            .frame(width: 0, height: 0)
            .alert("Choose Library Location", isPresented: $library.needsLibraryLocationSetup) {
                Button("Choose Location") {
                    showLibraryLocationPicker()
                }
                Button("Cancel", role: .cancel) {
                    library.needsLibraryLocationSetup = false
                }
            } message: {
                Text("The app needs permission to store your music library. Please select a folder where the library will be saved (e.g., Documents or Desktop).")
            }
    }

    private func showLibraryLocationPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.message = "Choose a location for your Music Library"
        panel.prompt = "Choose"

        panel.begin { response in
            DispatchQueue.main.async {
                if response == .OK, let url = panel.url {
                    // User selected a location
                    self.library.setLibraryLocation(url: url)
                } else {
                    // User cancelled - keep showing sample data
                    self.library.needsLibraryLocationSetup = false
                }
            }
        }
    }
}

#Preview {
    // Provide a preview using a LibraryManager instance.
    LibraryLocationPicker(library: AppLibraryService())
}
