# Music Player UI Layout

This document describes the visual layout of the Music Player macOS application.

## Main Window Layout

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  TOP BAR                                                                    │
│  ◀ ⏸ ▶   [Album Art] Track Name • Artist • Album    0:00 ──●─── 3:00  🔍  │
├──────────┬──────────────────────────────────────────────────────────────────┤
│          │                                                                  │
│ SIDEBAR  │  MAIN CONTENT AREA                                              │
│          │                                                                  │
│ LIBRARY  │  ┌─ Albums ──────────────────────────────────── □ ≡ Import ─┐  │
│ • Artists│  │                                                             │  │
│ • Albums │  │  ┌────┐ ┌────┐ ┌────┐ ┌────┐                               │  │
│ • Songs  │  │  │[🎵]│ │[🎵]│ │[🎵]│ │[🎵]│                               │  │
│          │  │  └────┘ └────┘ └────┘ └────┘                               │  │
│ COLLECT. │  │  Album  Album  Album  Album                                │  │
│ • Favs   │  │  Artist Artist Artist Artist                               │  │
│ + New    │  │                                                             │  │
│          │  │  ┌────┐ ┌────┐ ┌────┐ ┌────┐                               │  │
│          │  │  │[🎵]│ │[🎵]│ │[🎵]│ │[🎵]│                               │  │
│          │  │  └────┘ └────┘ └────┘ └────┘                               │  │
│          │  │  Album  Album  Album  Album                                │  │
│          │  │  Artist Artist Artist Artist                               │  │
│          │  │                                                             │  │
│          │  └─────────────────────────────────────────────────────────────┘  │
│          │                                                                  │
└──────────┴──────────────────────────────────────────────────────────────────┘
```

## Component Breakdown

### Top Bar (TopBarView)
- **Left section:** Playback controls
  - Skip backward button (◀)
  - Play/Pause button (⏸/▶)
  - Skip forward button (▶)
  
- **Center section:** Currently playing track
  - Album artwork (50x50 placeholder)
  - Track title (bold)
  - Artist • Album (secondary text)
  - Progress bar
  - Current time / Total time
  
- **Right section:** Search
  - Search icon (🔍)
  - Search text field
  - Clear button (X) when text is present

### Sidebar (SidebarView)
- **Library section:**
  - "LIBRARY" header
  - Artists (🎤 icon)
  - Albums (📦 icon)
  - Songs (🎵 icon)
  - Selection highlight on active view

- **Collections section:**
  - "COLLECTIONS" header with + button
  - List of user-created collections
  - Each collection has a playlist icon
  - Selection highlight on active collection

### Main Content Area (MainContentView)

#### Header
- View title (e.g., "Albums", "Artists", "Songs", or collection name)
- View mode toggles (Grid □ / List ≡)
- Import button (primary button style)

#### Grid View Mode
- **Albums:**
  - Square album art placeholders with music note icon
  - Album name (bold)
  - Artist name (secondary)
  - Track count

- **Artists:**
  - Circular artist image placeholders with person icon
  - Artist name (bold)
  - Album count • Track count

- **Songs:**
  - Square artwork placeholders
  - Track title (bold)
  - Artist name (secondary)
  - Album name (tertiary)

#### List View Mode
Columns:
- # (track number)
- Title
- Artist
- Album
- Duration

Features:
- Header row with column labels
- Hover highlighting
- Row dividers
- Click to play

## Color Scheme

- Background: System window background
- Sidebar: System control background
- Accent: System accent color (blue by default)
- Text: Primary, secondary, and tertiary system colors
- Hover states: Accent color at 10% opacity

## Typography

- Title: Large, bold
- Headers: Small caps, secondary color
- Track names: Headline weight
- Metadata: Subheadline, secondary/tertiary colors
- Time: Monospaced caption

## Spacing

- Minimum window size: 900x600
- Sidebar width: 200-250px
- Grid items: 160-200px adaptive columns
- Padding: 8-16px consistent throughout
- Grid spacing: 16px between items

## Interactions

1. **Click album/track:** Start playback
2. **Click sidebar item:** Change view
3. **Click play/pause:** Toggle playback
4. **Click skip buttons:** Skip 10 seconds
5. **Type in search:** Filter current view
6. **Click Import:** Open file picker
7. **Click + in Collections:** Create new collection
8. **Click grid/list toggle:** Change display mode
9. **Hover over list row:** Highlight row
