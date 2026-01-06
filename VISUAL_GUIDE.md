# Music Player Visual Guide

## Application Screenshot Description

Since this is a macOS application that requires Xcode to build and run, below is a detailed description of what the application looks like when running.

### Overall Layout

The application window has a modern macOS appearance with three main sections:

```
┌───────────────────────────────────────────────────────────────────────────────┐
│                              TOP BAR (Height: ~90px)                           │
│ ┌───────────────────────────────────────────────────────────────────────────┐ │
│ │  ◀  ⏸  ▶    [Album] Sample Song 1          0:00 ━━●━━━━━ 3:00    🔍 Search│ │
│ │              Sample Artist 1 • Sample Album 1                              │ │
│ └───────────────────────────────────────────────────────────────────────────┘ │
├──────────────┬────────────────────────────────────────────────────────────────┤
│              │                                                                │
│  SIDEBAR     │                    MAIN CONTENT AREA                           │
│  (200-250px) │                                                                │
│              │  ┌─ Albums ──────────────────────────────── [□] [≡] Import ─┐ │
│ LIBRARY      │  │                                                            │ │
│  🎤 Artists  │  │  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐          │ │
│  📦 Albums   │  │  │   🎵   │  │   🎵   │  │   🎵   │  │   🎵   │          │ │
│  🎵 Songs    │  │  │        │  │        │  │        │  │        │          │ │
│              │  │  └────────┘  └────────┘  └────────┘  └────────┘          │ │
│ ───────────  │  │  Sample      Sample      Another     Sample               │ │
│              │  │  Album 1     Album 2     Album       Album 3              │ │
│ COLLECTIONS  │  │  Sample      Sample      Sample      Sample               │ │
│  🎼 Favorites│  │  Artist 1    Artist 2    Artist 2    Artist 3             │ │
│  + New       │  │  2 songs     3 songs     1 song      4 songs              │ │
│              │  │                                                            │ │
│              │  │  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐          │ │
│              │  │  │   🎵   │  │   🎵   │  │   🎵   │  │   🎵   │          │ │
│              │  │  │        │  │        │  │        │  │        │          │ │
│              │  │  └────────┘  └────────┘  └────────┘  └────────┘          │ │
│              │  │  Album       Album       Album       Album                │ │
│              │  │                                                            │ │
│              │  └────────────────────────────────────────────────────────────┘ │
│              │                                                                │
└──────────────┴────────────────────────────────────────────────────────────────┘
```

### Detailed Component Views

#### 1. Top Bar - Playback Controls

**Left Section (Controls):**
- ◀ Skip Backward button (10 seconds)
- ⏸ Play/Pause button (large, circular) - toggles to ▶ when paused
- ▶ Skip Forward button (10 seconds)

**Center Section (Now Playing):**
```
┌─────┐  Sample Song 1
│  🎵 │  Sample Artist 1 • Sample Album 1
└─────┘  
         0:00 ━━━━●━━━━━━━━━━ 3:00
```
- 50x50px album artwork placeholder (gray rounded rectangle with music note icon)
- Track title in bold (headline font)
- Artist and album in gray text with bullet separator
- Progress bar showing current position
- Time stamps on both ends

**Right Section (Search):**
```
┌──────────────────┐
│ 🔍  [Search...] ⓧ│
└──────────────────┘
```
- Magnifying glass icon
- Text input field
- Clear button (X) appears when text is entered

#### 2. Sidebar - Navigation

**Library Section:**
```
LIBRARY
┌──────────────────┐
│ 🎤 Artists       │
├──────────────────┤
│ 📦 Albums        │ ← Selected (blue highlight)
├──────────────────┤
│ 🎵 Songs         │
└──────────────────┘
```
- Section header in small caps, gray
- Each item has an icon and label
- Selected item has blue background (20% opacity)
- Hover effect on other items

**Collections Section:**
```
COLLECTIONS      +
┌──────────────────┐
│ 🎼 Favorites     │
└──────────────────┘
```
- Header with "+ New" button on the right
- Each collection listed with playlist icon
- Can click to view collection contents

#### 3. Main Content - Grid View (Albums)

**Header Bar:**
```
Albums                                [□] [≡]  [Import]
```
- Large, bold title
- Grid/List toggle buttons (grid selected = darker)
- Primary blue "Import" button

**Grid Layout:**
```
┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐
│   🎵   │  │   🎵   │  │   🎵   │  │   🎵   │  │   🎵   │
│        │  │        │  │        │  │        │  │        │
└────────┘  └────────┘  └────────┘  └────────┘  └────────┘
Sample      Sample      Another     More        Test
Album 1     Album 2     Album       Albums      Album
Sample      Sample      Sample      Various     Test
Artist 1    Artist 1    Artist 2    Artists     Artist
2 songs     3 songs     1 song      5 songs     4 songs
```
- Adaptive grid (2-6 columns depending on window width)
- Square artwork placeholders (160-200px)
- Album name in bold
- Artist name in gray
- Song count in smaller gray text
- 16px spacing between items

#### 4. Main Content - List View (Songs)

**List Header:**
```
#   Title                Artist              Album               Duration
────────────────────────────────────────────────────────────────────────
```

**List Rows:**
```
1   Sample Song 1        Sample Artist 1     Sample Album 1      3:00
2   Sample Song 2        Sample Artist 1     Sample Album 1      3:20
3   Another Song         Sample Artist 2     Another Album       3:40
────────────────────────────────────────────────────────────────────────
```
- Fixed column widths
- Alternating row hover effect (light blue background)
- Click anywhere on row to play
- Clean divider lines between rows

#### 5. Artists View (Grid)

```
┌────────┐  ┌────────┐  ┌────────┐
│   👤   │  │   👤   │  │   👤   │
│  ( )   │  │  ( )   │  │  ( )   │
└────────┘  └────────┘  └────────┘
Sample      Sample      Sample
Artist 1    Artist 2    Artist 3
2 albums •  1 album •   3 albums •
5 songs     3 songs     12 songs
```
- Circular placeholders for artist images
- Person icon in the center
- Artist name in bold
- Album and song counts

### Color Scheme

**Background Colors:**
- Window background: Light gray (system)
- Sidebar: Slightly darker gray (system control background)
- Content area: White/light background

**Accent Colors:**
- Primary: Blue (system accent)
- Selection: Blue at 20% opacity
- Hover: Blue at 10% opacity

**Text Colors:**
- Primary text: Black/dark gray
- Secondary text: Medium gray (artist names, metadata)
- Tertiary text: Light gray (timestamps, counts)

### Interactions

**Visual Feedback:**
1. **Hover states:** Buttons and list items lighten or show blue tint
2. **Click states:** Brief animation/flash
3. **Selection states:** Blue background highlight
4. **Playing indicator:** Progress bar moves smoothly
5. **Search filtering:** Results update in real-time

**Animations:**
- Smooth progress bar animation (updates 10x per second)
- Fade transitions when switching views
- Hover effects with subtle transitions
- Button press animations

### Window Properties

- **Minimum size:** 900px × 600px
- **Title bar:** Hidden for modern look
- **Resizable:** Yes, grid adapts to width
- **Default size:** ~1200px × 800px

### Responsive Behavior

**Window Width:**
- < 1000px: 2 columns in grid
- 1000-1400px: 3-4 columns
- 1400-1800px: 4-5 columns  
- > 1800px: 5-6 columns

**Sidebar:**
- Fixed width (200-250px)
- Does not collapse

**Top Bar:**
- Always visible
- Components reflow on narrow windows

This is what users will see when they build and run the Music Player application in Xcode!
