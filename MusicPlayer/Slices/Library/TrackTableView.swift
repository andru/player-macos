import SwiftUI

// MARK: - Column Configuration

/// Configuration for table columns - allows parent views to customize display
struct TrackTableColumn: Identifiable {
    let id: String
    let title: String
    let width: CGFloat?
    let minWidth: CGFloat?
    let maxWidth: CGFloat?
    
    init(id: String, title: String, width: CGFloat? = nil, minWidth: CGFloat? = nil, maxWidth: CGFloat? = nil) {
        self.id = id
        self.title = title
        self.width = width
        self.minWidth = minWidth
        self.maxWidth = maxWidth
    }
}

// MARK: - Track Table View

struct TrackTableView: View {
    @EnvironmentObject var library: LibraryManager
    @EnvironmentObject var preferences: PreferencesService
    var filteredTracks: [Track]
    let audioPlayer: AudioPlayer
    
    // Column configuration - customizable by parent
    var columns: [TrackTableColumn] = [
        TrackTableColumn(id: "number", title: "#", width: 40, minWidth: 40, maxWidth: 60),
        TrackTableColumn(id: "title", title: "Title", minWidth: 100),
        TrackTableColumn(id: "artist", title: "Artist", width: 200, minWidth: 100),
        TrackTableColumn(id: "album", title: "Album", width: 200, minWidth: 100),
        TrackTableColumn(id: "duration", title: "Duration", width: 80, minWidth: 60, maxWidth: 100)
    ]
    
    // State for selection
    @State private var selection = Set<Track.ID>()
    
    var body: some View {
        DoubleClickableTable(
            tracks: filteredTracks,
            selection: $selection,
            columns: columns,
            onDoubleClick: handleDoubleClick,
            library: library,
            audioPlayer: audioPlayer
        )
    }
    
    private func handleDoubleClick() {
        // Double-click: play selected track(s)
        if !selection.isEmpty {
            let selectedTracks = filteredTracks.filter { selection.contains($0.id) }
            if !selectedTracks.isEmpty {
                audioPlayer.queueTracks(selectedTracks, startPlaying: true, behavior: preferences.playbackBehavior)
            }
        }
    }
}

// MARK: - Double-Clickable Table Wrapper

private struct DoubleClickableTable: View {
    let tracks: [Track]
    @Binding var selection: Set<Track.ID>
    let columns: [TrackTableColumn]
    let onDoubleClick: () -> Void
    let library: LibraryManager?
    let audioPlayer: AudioPlayer
    
    var body: some View {
        TableWithDoubleClick(
            tracks: tracks,
            selection: $selection,
            columns: columns,
            onDoubleClick: onDoubleClick,
            library: library,
            audioPlayer: audioPlayer
        )
    }
}

// MARK: - NSViewRepresentable Table with Double-Click Support

private struct TableWithDoubleClick: NSViewRepresentable {
    let tracks: [Track]
    @Binding var selection: Set<Track.ID>
    let columns: [TrackTableColumn]
    let onDoubleClick: () -> Void
    let library: LibraryManager?
    let audioPlayer: AudioPlayer
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let tableView = NSTableView()
        
        tableView.delegate = context.coordinator
        tableView.dataSource = context.coordinator
        tableView.allowsMultipleSelection = true
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.style = .automatic
        tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        
        // Enable double-click
        tableView.target = context.coordinator
        tableView.doubleAction = #selector(Coordinator.tableViewDoubleClicked(_:))
        
        // Add columns
        for column in columns {
            let tableColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(column.id))
            tableColumn.title = column.title
            
            if let width = column.width {
                tableColumn.width = width
            }
            if let minWidth = column.minWidth {
                tableColumn.minWidth = minWidth
            }
            if let maxWidth = column.maxWidth {
                tableColumn.maxWidth = maxWidth
            }
            
            tableColumn.resizingMask = .userResizingMask
            
            // Set sort descriptor for sortable columns (all columns except "number" are sortable)
            if column.id != "number" {
                let sortDescriptor = NSSortDescriptor(key: column.id, ascending: true)
                tableColumn.sortDescriptorPrototype = sortDescriptor
            }
            
            tableView.addTableColumn(tableColumn)
        }
        
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        
        context.coordinator.tableView = tableView
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let tableView = scrollView.documentView as? NSTableView else { return }
        
        context.coordinator.updateTracks(tracks)
        context.coordinator.columns = columns
        
        tableView.reloadData()
        
        // Sync selection from SwiftUI state
        let selectedRows = IndexSet(selection.compactMap { id in
            context.coordinator.sortedTracks.firstIndex(where: { $0.id == id })
        })
        if tableView.selectedRowIndexes != selectedRows {
            tableView.selectRowIndexes(selectedRows, byExtendingSelection: false)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            tracks: tracks,
            columns: columns,
            selection: $selection,
            onDoubleClick: onDoubleClick,
            library: library,
            audioPlayer: audioPlayer
        )
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, NSTableViewDelegate, NSTableViewDataSource {
        var originalTracks: [Track]
        var sortedTracks: [Track]
        var columns: [TrackTableColumn]
        @Binding var selection: Set<Track.ID>
        let onDoubleClick: () -> Void
        let library: LibraryManager?
        let audioPlayer: AudioPlayer
        weak var tableView: NSTableView?
        
        init(tracks: [Track], columns: [TrackTableColumn], selection: Binding<Set<Track.ID>>, onDoubleClick: @escaping () -> Void, library: LibraryManager?, audioPlayer: AudioPlayer) {
            self.originalTracks = tracks
            self.sortedTracks = tracks
            self.columns = columns
            self._selection = selection
            self.onDoubleClick = onDoubleClick
            self.library = library
            self.audioPlayer = audioPlayer
        }
        
        func updateTracks(_ newTracks: [Track]) {
            // Keep the current sort descriptor if any
            if let tableView = tableView,
               let sortDescriptor = tableView.sortDescriptors.first {
                self.originalTracks = newTracks
                applySort(sortDescriptor: sortDescriptor)
            } else {
                self.originalTracks = newTracks
                self.sortedTracks = newTracks
            }
        }
        
        private func applySort(sortDescriptor: NSSortDescriptor) {
            guard let columnId = sortDescriptor.key else { return }
            
            // Sort tracks based on the column
            sortedTracks = originalTracks.sorted { track1, track2 in
                let ascending = sortDescriptor.ascending
                
                switch columnId {
                case "title":
                    return ascending ? track1.title < track2.title : track1.title > track2.title
                case "artist":
                    return ascending ? track1.artist < track2.artist : track1.artist > track2.artist
                case "album":
                    return ascending ? track1.album < track2.album : track1.album > track2.album
                case "duration":
                    return ascending ? track1.duration < track2.duration : track1.duration > track2.duration
                default:
                    return true
                }
            }
        }
        
        // MARK: - NSTableViewDataSource
        
        func numberOfRows(in tableView: NSTableView) -> Int {
            return sortedTracks.count
        }
        
        // MARK: - NSTableViewDelegate
        
        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            guard row < sortedTracks.count else { return nil }
            let track = sortedTracks[row]
            
            guard let columnId = tableColumn?.identifier.rawValue else { return nil }
            
            let cellIdentifier = NSUserInterfaceItemIdentifier("Cell_\(columnId)")
            
            var cell = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView
            
            if cell == nil {
                cell = NSTableCellView()
                cell?.identifier = cellIdentifier
                
                let textField = NSTextField()
                textField.isBordered = false
                textField.backgroundColor = .clear
                textField.isEditable = false
                textField.lineBreakMode = .byTruncatingTail
                textField.translatesAutoresizingMaskIntoConstraints = false
                
                cell?.addSubview(textField)
                cell?.textField = textField
                
                NSLayoutConstraint.activate([
                    textField.leadingAnchor.constraint(equalTo: cell!.leadingAnchor, constant: 4),
                    textField.trailingAnchor.constraint(equalTo: cell!.trailingAnchor, constant: -4),
                    textField.centerYAnchor.constraint(equalTo: cell!.centerYAnchor)
                ])
            }
            
            // Set cell content based on column
            switch columnId {
            case "number":
                cell?.textField?.stringValue = "\(row + 1)"
                cell?.textField?.textColor = .secondaryLabelColor
                cell?.textField?.alignment = .natural
            case "title":
                cell?.textField?.stringValue = track.title
                cell?.textField?.textColor = .labelColor
                cell?.textField?.alignment = .natural
            case "artist":
                cell?.textField?.stringValue = track.artist
                cell?.textField?.textColor = .secondaryLabelColor
                cell?.textField?.alignment = .natural
            case "album":
                cell?.textField?.stringValue = track.album
                cell?.textField?.textColor = .secondaryLabelColor
                cell?.textField?.alignment = .natural
            case "duration":
                cell?.textField?.stringValue = track.formattedDuration
                cell?.textField?.textColor = .secondaryLabelColor
                cell?.textField?.alignment = .right
            default:
                cell?.textField?.stringValue = ""
            }
            
            return cell
        }
        
        func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
            guard row < sortedTracks.count else { return nil }
            let rowView = TrackTableRowView()
            rowView.track = sortedTracks[row]
            rowView.audioPlayer = audioPlayer
            rowView.library = library
            return rowView
        }
        
        func tableViewSelectionDidChange(_ notification: Notification) {
            guard let tableView = notification.object as? NSTableView else { return }
            
            let selectedRows = tableView.selectedRowIndexes
            let selectedIDs = Set(selectedRows.compactMap { row -> Track.ID? in
                guard row < sortedTracks.count else { return nil }
                return sortedTracks[row].id
            })
            
            // Update SwiftUI state
            if selection != selectedIDs {
                selection = selectedIDs
            }
        }
        
        func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
            guard let sortDescriptor = tableView.sortDescriptors.first else { return }
            
            applySort(sortDescriptor: sortDescriptor)
            tableView.reloadData()
        }
        
        @objc func tableViewDoubleClicked(_ sender: AnyObject) {
            onDoubleClick()
        }
    }
}

// MARK: - Custom Row View for Context Menu

class TrackTableRowView: NSTableRowView {
    var track: Track?
    var audioPlayer: AudioPlayer?
    var library: LibraryManager?
    
    override var menu: NSMenu? {
        get {
            guard let track = track, let audioPlayer = audioPlayer else { return nil }
            
            let menu = NSMenu()
            
            let playNowItem = NSMenuItem(title: "Play Now", action: #selector(playNow), keyEquivalent: "")
            playNowItem.target = self
            menu.addItem(playNowItem)
            
            let nextQueueItem = NSMenuItem(title: "Next in Queue", action: #selector(addToQueueNext), keyEquivalent: "")
            nextQueueItem.target = self
            menu.addItem(nextQueueItem)
            
            let endQueueItem = NSMenuItem(title: "End of Queue", action: #selector(addToQueueEnd), keyEquivalent: "")
            endQueueItem.target = self
            menu.addItem(endQueueItem)
            
            menu.addItem(NSMenuItem.separator())
            
            if library != nil {
                let favoriteItem = NSMenuItem(title: "Favourite", action: #selector(toggleFavorite), keyEquivalent: "")
                favoriteItem.target = self
                menu.addItem(favoriteItem)
                
                let collectionItem = NSMenuItem(title: "Add to Collection", action: #selector(addToCollection), keyEquivalent: "")
                collectionItem.target = self
                menu.addItem(collectionItem)
                
                let playlistItem = NSMenuItem(title: "Add to Playlist", action: #selector(addToPlaylist), keyEquivalent: "")
                playlistItem.target = self
                menu.addItem(playlistItem)
                
                menu.addItem(NSMenuItem.separator())
                
                let removeItem = NSMenuItem(title: "Remove from Library", action: #selector(removeFromLibrary), keyEquivalent: "")
                removeItem.target = self
                menu.addItem(removeItem)
                
                let refreshItem = NSMenuItem(title: "Refresh from Source", action: #selector(refreshFromSource), keyEquivalent: "")
                refreshItem.target = self
                menu.addItem(refreshItem)
                
                let editItem = NSMenuItem(title: "Edit Info", action: #selector(editInfo), keyEquivalent: "")
                editItem.target = self
                menu.addItem(editItem)
            }
            
            return menu
        }
        set { super.menu = newValue }
    }
    
    @objc private func playNow() {
        guard let track = track, let audioPlayer = audioPlayer else { return }
        audioPlayer.playNow(track)
    }
    
    @objc private func addToQueueNext() {
        guard let track = track, let audioPlayer = audioPlayer else { return }
        audioPlayer.addToQueueNext(track)
    }
    
    @objc private func addToQueueEnd() {
        guard let track = track, let audioPlayer = audioPlayer else { return }
        audioPlayer.addToQueueEnd(track)
    }
    
    @objc private func toggleFavorite() {
        guard let track = track, let library = library else { return }
        library.toggleFavorite(track: track)
    }
    
    @objc private func addToCollection() {
        // TODO: Show collection picker
        print("Add to collection")
    }
    
    @objc private func addToPlaylist() {
        // TODO: Show playlist picker
        print("Add to playlist")
    }
    
    @objc private func removeFromLibrary() {
        guard let track = track, let library = library else { return }
        library.removeFromLibrary(track: track)
    }
    
    @objc private func refreshFromSource() {
        guard let track = track, let library = library else { return }
        library.refreshFromSource(track: track)
    }
    
    @objc private func editInfo() {
        guard let track = track, let library = library else { return }
        library.editInfo(track: track)
    }
}
