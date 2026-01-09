import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var library: AppLibraryService
    @Binding var selectedView: LibraryViewMode
    @Binding var selectedAlbum: Album?
    @Binding var selectedCollection: Collection?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Library section
            VStack(alignment: .leading, spacing: 4) {
                Text("LIBRARY")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                    .padding(.bottom, 4)
                
                ForEach(LibraryViewMode.allCases, id: \.self) { view in
                    SidebarItemView(
                        title: view.rawValue,
                        icon: iconForView(view),
                        isSelected: selectedView == view && selectedCollection == nil
                    ) {
                        selectedView = view
                        selectedCollection = nil
                        selectedAlbum = nil
                    }
                }
            }
            
            Divider()
                .padding(.vertical, 8)
            
            // Collections section
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("COLLECTIONS")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: createNewCollection) {
                        Image(systemName: "plus")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 4)
                
                ForEach(library.collections) { collection in
                    SidebarItemView(
                        title: collection.name,
                        icon: "music.note.list",
                        isSelected: selectedCollection?.id == collection.id
                    ) {
                        selectedCollection = collection
                    }
                }
            }
            
            Spacer()
        }
        .frame(minWidth: 200, maxWidth: 250)
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    private func iconForView(_ view: LibraryViewMode) -> String {
        switch view {
        case .artists:
            return "music.mic"
        case .albums:
            return "square.stack"
        case .songs:
            return "music.note"
        }
    }
    
    private func createNewCollection() {
        let newCollection = Collection(name: "New Collection")
        library.addCollection(newCollection)
    }
}

struct SidebarItemView: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 16)
                Text(title)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .foregroundColor(isSelected ? .primary : .secondary)
        .padding(.horizontal, 8)
    }
}
