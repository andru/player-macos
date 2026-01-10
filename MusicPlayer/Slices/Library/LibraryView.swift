import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var container: AppContainer
    @EnvironmentObject var preferences: PreferencesService
    
    let vm: LibraryViewModel

    // Make `body` available for the deployment target (macOS 13+). If any
    // APIs used inside require macOS 14+, guard with `if #available` there.
    var body: some View {
    
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                // Import button
                Button(action: { Task { try await importMusicDirectory() } }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Import")
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Divider()
            
            // Content
            HStack {
                if let album = vm.selectedAlbum {
                    AlbumDetailView(
                        vm: vm,
                        album: album,
                        onBack: {
                            vm.selectedAlbum = nil
                        }
                    )
                } else {
                    if vm.selectedView == .albums || vm.selectedCollection != nil {
                        AlbumsView(vm: vm)
                    } else if vm.selectedView == .artists {
                        ArtistsView(vm: vm)
                    } else {
                        SongsView(vm: vm)
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
        .frame(maxHeight: .infinity)
    
    }
    
    
    private var viewTitle: String {
        return "Library"
//        if let collection = selectedCollection {
//            return collection.name
//        }
//        return selectedView.rawValue
    }
    
    private func importMusicFiles() async {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.audio]
        
        if panel.runModal() == .OK {
//            await library.importFiles(urls: panel.urls)
        }
    }
    
    private func importMusicDirectory() async throws {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = false
        panel.message = "Choose a folder to import music from"
        panel.prompt = "Import"
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                let importReport = try await container.featureDeps.library.musicImportService.importDirectory(url: url)
            } catch is CancellationError {
                // swallow
            }
        }
    }
}
