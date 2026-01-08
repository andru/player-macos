// MARK: - View Selection
enum LibraryViewMode: String, CaseIterable {
    case artists = "Artists"
    case albums = "Albums"
    case songs = "Songs"
}

// MARK: - Display Mode
enum DisplayMode {
    case grid
    case list
}

enum LibrarySortOption: String, CaseIterable {
    case title = "Title"
    case album = "Album"
    case artist = "Artist"
}
