import SwiftUI

struct GeneralPreferencesView: View {
    @ObservedObject var library: LibraryManager
    @State private var showingLocationPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("General")
                .font(.title2)
                .bold()
            
            Divider()
            
            // Library Location Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Library Location")
                    .font(.headline)
                
                HStack {
                    Text(libraryLocationPath)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Spacer()
                    
                    Button("Choose...") {
                        showingLocationPicker = true
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
        .fileImporter(
            isPresented: $showingLocationPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    library.setLibraryLocation(url: url)
                }
            case .failure(let error):
                print("Error selecting library location: \(error)")
            }
        }
    }
    
    private var libraryLocationPath: String {
        if let libraryURL = library.libraryURL {
            // Show the parent directory (not the .library bundle itself)
            return libraryURL.deletingLastPathComponent().path
        } else {
            return "No library location set"
        }
    }
}
