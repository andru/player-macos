# Music Player for macOS

A native macOS music player and library manager built with Swift and SwiftUI.

## Features

### User Interface

- **Three-panel layout:**
  - **Left Sidebar:** Navigate between library views and collections
    - Artists view
    - Albums view
    - Songs view
    - User-defined collections with "+" button to create new ones
  - **Top Bar:** Playback controls and currently playing track info
    - Play/Pause button
    - Previous/Next buttons to navigate queue
    - Current track information with album artwork
    - Playback progress bar with time display
    - Queue button to show/hide queue sidebar
    - Search box to filter library content
  - **Main Content Area:** Display music library in grid or list view
    - Toggle between grid and list display modes
    - Import button to add music files
    - Responsive grid layout for albums, artists, and songs
    - Detailed list view with columns for track metadata
  - **Right Sidebar (Queue):** View and manage the song queue
    - Shows all queued tracks with artwork and metadata
    - Highlights currently playing track
    - Grays out previously played tracks
    - Drag-and-drop to reorder queue
    - Clear queue button

### Functionality

- **Audio Playback:** 
  - Built on AVFoundation for native audio playback
  - Support for common audio formats (MP3, M4A, FLAC, WAV, etc.)
  - Real-time playback progress tracking
  - Song queue with automatic progression
  - Previous/Next navigation through queue
  - Played tracks remain visible but grayed out

- **Library Management:**
  - Import music files from your file system
  - Automatic metadata extraction from audio files
  - Organize music by Artists, Albums, and Songs
  - Create custom collections (playlists)
  - Search across all tracks, artists, and albums
  - Persistent library storage in .library bundle
  - Attempts to use ~/Music by default, or prompts for location if restricted
  - Library data survives app reinstalls and updates

- **Views:**
  - **Artists View:** Browse by artist with album counts
  - **Albums View:** Grid of albums with artwork placeholders
  - **Songs View:** All tracks in your library
  - **Collections:** User-defined playlists

## Requirements

- macOS 13.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

## Building and Running

1. Open `MusicPlayer.xcodeproj` in Xcode
2. Select the MusicPlayer scheme
3. Click the Run button or press Cmd+R

The app will launch with sample data to demonstrate the interface.

## Usage

### Importing Music

1. Click the "Import" button in the top-right corner
2. Select one or more audio files from the file picker
3. The tracks will be automatically added to your library

### Playing Music

1. Navigate to any view (Artists, Albums, or Songs)
2. Click on an album, artist, or track to start playback
   - **Albums:** All tracks in the album are queued automatically
   - **Artists:** All tracks by the artist are queued automatically
   - **Individual tracks:** Single track is queued
3. Use the playback controls in the top bar to control playback
4. The progress bar shows current playback position
5. Use Previous/Next buttons to navigate through the queue

### Using the Queue

1. Click the queue button (list icon) in the top bar to show the queue sidebar
2. The queue displays all upcoming tracks and previously played tracks
3. Currently playing track is highlighted
4. Previously played tracks appear grayed out
5. Drag and drop tracks to reorder the queue
6. Click any track in the queue to jump to it
7. Click "Clear" to empty the queue

### Creating Collections

1. Click the "+" button next to "COLLECTIONS" in the sidebar
2. A new collection will be created
3. Add tracks to collections by selecting them (functionality can be extended)

### Searching

1. Type in the search box in the top-right corner
2. The view will filter to show matching tracks, albums, or artists

### Display Modes

- Click the grid icon for grid view (album artwork layout)
- Click the list icon for list view (detailed table layout)

## Project Structure

```
MusicPlayer/
├── MusicPlayer.xcodeproj/      # Xcode project file
└── MusicPlayer/
    ├── MusicPlayerApp.swift    # App entry point
    ├── ContentView.swift       # Main view coordinator
    ├── SidebarView.swift       # Left sidebar navigation
    ├── TopBarView.swift        # Playback controls and search
    ├── MainContentView.swift   # Main content area with grid/list
    ├── MusicModels.swift       # Data models (Track, Album, Artist, Collection)
    ├── AudioPlayer.swift       # Audio playback engine
    ├── LibraryManager.swift    # Library management and data
    ├── Assets.xcassets/        # App assets and icons
    └── MusicPlayer.entitlements # App permissions
```

## Architecture

The app follows the MVVM (Model-View-ViewModel) pattern with SwiftUI:

- **Models:** `Track`, `Album`, `Artist`, `Collection` - Core data structures
- **ViewModels:** `LibraryManager`, `AudioPlayer` - Observable objects managing state
- **Views:** SwiftUI views for UI components

### Key Components

- **AudioPlayer:** Manages audio playback using AVAudioPlayer
- **LibraryManager:** Manages the music library, collections, and metadata
- **ContentView:** Main coordinator connecting all views
- **SidebarView:** Navigation sidebar with library views and collections
- **TopBarView:** Playback controls and track information
- **MainContentView:** Displays library content in grid or list format

## Permissions

The app requires the following permissions (defined in `MusicPlayer.entitlements`):
- File system access (read-only for user-selected files)
- Music library access (read-only)

## Future Enhancements

Potential features for future development:
- Album artwork loading from embedded metadata or online sources
- Playlist editing and management
- Audio equalizer and effects
- Shuffle and repeat modes
- Keyboard shortcuts
- Mini player mode
- iTunes/Music.app library import
- Smart playlists with filters
- Lyrics display
- iCloud sync for playlists

## License

This project is open source and available for use and modification.