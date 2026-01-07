# Preferences Window Implementation

This document describes the implementation of the preferences window with a tabbed interface.

## Overview

The preferences window is accessible from the app menu (MusicPlayer > Settings...) with keyboard shortcut **Cmd+,**. It provides a tabbed interface with two tabs:

1. **General** - Library location management
2. **Playback** - Playback behavior settings

## Architecture

### Files Created

1. **PreferencesManager.swift** - Manages application preferences
   - `PlaybackBehavior` enum with two cases:
     - `clearAndPlay`: Clears the queue and plays immediately
     - `appendToQueue`: Appends to the end of the queue
   - `PreferencesManager` class: ObservableObject that persists preferences to UserDefaults

2. **PreferencesWindow.swift** - Main preferences window with TabView
   - Uses SwiftUI TabView to organize preferences into tabs
   - Fixed size window (500x350)

3. **GeneralPreferencesView.swift** - General preferences tab
   - Displays current library location
   - "Choose..." button to select a different library location
   - Uses file importer to allow folder selection

4. **PlaybackPreferencesView.swift** - Playback preferences tab
   - Radio button interface for selecting playback behavior
   - Updates PreferencesManager when selection changes

### Integration Points

1. **MusicPlayerApp.swift**
   - Created `@StateObject` instances for `LibraryManager` and `PreferencesManager`
   - Added `Settings { }` scene to enable preferences window
   - Passes objects to ContentView via environment objects

2. **ContentView.swift**
   - Changed from `@StateObject` to `@EnvironmentObject` for library and preferences
   - Ensures preferences are accessible throughout the view hierarchy

3. **MainContentView.swift**
   - Added `@EnvironmentObject var preferences: PreferencesManager`
   - Updated `queueTracks` calls to pass `behavior: preferences.playbackBehavior`

4. **AudioPlayer.swift**
   - Updated `queueTracks` method to accept `behavior: PlaybackBehavior` parameter
   - Implements two behaviors:
     - `clearAndPlay`: Clears queue and plays immediately
     - `appendToQueue`: Appends tracks to queue, starts playing if nothing is playing

## Usage

### Accessing Preferences

1. From the menu bar: **MusicPlayer > Settings...**
2. Using keyboard shortcut: **Cmd+,**

### General Tab

The General tab displays:
- **Library Location**: Shows the current library directory path
- **Choose...** button: Opens a folder picker to select a new library location

When a new location is selected, the app will create or use a `MusicPlayer.library` bundle in that directory.

### Playback Tab

The Playback tab provides radio buttons to choose playback behavior:

- ○ **Clear queue and play immediately** (Default)
  - When you click on a song or album, the current queue is cleared and the new selection plays immediately

- ○ **Append to end of queue**
  - When you click on a song or album, it's added to the end of the current queue
  - If nothing is playing, it starts playing immediately

## Testing

Unit tests are provided in `MusicPlayerTests/PreferencesManagerTests.swift`:

- Tests default playback behavior
- Tests persistence of preferences to UserDefaults
- Tests restoration of preferences on app restart
- Tests PlaybackBehavior enum cases and raw values

## Technical Details

### State Management

- **PreferencesManager** uses `@Published` properties with `didSet` to automatically persist changes to UserDefaults
- The `playbackBehaviorKey` constant ("PlaybackBehavior") identifies the preference in UserDefaults
- Default behavior is `clearAndPlay`

### UI Components

- Uses native SwiftUI TabView for tabs
- Radio buttons implemented using Button with SF Symbols:
  - `largecircle.fill.circle` for selected state
  - `circle` for unselected state
- General preferences uses `.fileImporter` modifier for folder selection

### Keyboard Shortcut

The Cmd+, keyboard shortcut is automatically provided by the `Settings { }` scene in SwiftUI. This follows macOS conventions where Cmd+, always opens preferences.

## Future Enhancements

Potential improvements could include:

- Additional playback preferences (shuffle mode, repeat mode)
- Audio quality settings
- Keyboard shortcut customization
- Theme/appearance settings
- Advanced library management options
