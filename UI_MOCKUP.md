# UI Mockup - Preferences Window

## Window Overview
```
┌─────────────────────────────────────────────────────┐
│ MusicPlayer Settings                           ⚫ 🟡 🟢 │
├─────────────────────────────────────────────────────┤
│  ⚙️ General      ▶️ Playback                        │
├─────────────────────────────────────────────────────┤
│                                                     │
│  [SELECTED TAB CONTENT AREA]                       │
│                                                     │
│                                                     │
│                                                     │
│                                                     │
│                                                     │
│                                                     │
│                                                     │
└─────────────────────────────────────────────────────┘
```
Window Size: 500 x 350 pixels

## General Tab
```
┌─────────────────────────────────────────────────────┐
│ MusicPlayer Settings                           ⚫ 🟡 🟢 │
├─────────────────────────────────────────────────────┤
│  ⚙️ General      ▶️ Playback                        │
├─────────────────────────────────────────────────────┤
│                                                     │
│  General                                            │
│  ─────────────────────────────────────────────      │
│                                                     │
│  Library Location                                   │
│  ┌───────────────────────────────┬────────────┐   │
│  │ /Users/username/Music         │  Choose... │   │
│  └───────────────────────────────┴────────────┘   │
│                                                     │
│                                                     │
│                                                     │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### Elements:
- **Title**: "General" (font: .title2, bold)
- **Divider**: Horizontal line separator
- **Section Header**: "Library Location" (font: .headline)
- **Path Display**: Gray text showing current library path
  - Truncates in the middle if too long
  - Light gray background
  - Rounded corners (6px radius)
- **Choose Button**: Standard macOS button
  - Opens system folder picker
  - Blue accent color when clicked

## Playback Tab
```
┌─────────────────────────────────────────────────────┐
│ MusicPlayer Settings                           ⚫ 🟡 🟢 │
├─────────────────────────────────────────────────────┤
│  ⚙️ General      ▶️ Playback                        │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Playback                                           │
│  ─────────────────────────────────────────────      │
│                                                     │
│  When playing a song or album:                      │
│  ┌─────────────────────────────────────────────┐  │
│  │  ◉ Clear queue and play immediately         │  │
│  │                                              │  │
│  │  ○ Append to end of queue                   │  │
│  └─────────────────────────────────────────────┘  │
│                                                     │
│                                                     │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### Elements:
- **Title**: "Playback" (font: .title2, bold)
- **Divider**: Horizontal line separator
- **Section Header**: "When playing a song or album:" (font: .headline)
- **Radio Buttons**: Custom implementation using SF Symbols
  - Selected: ◉ (largecircle.fill.circle) in accent color
  - Unselected: ○ (circle) in gray
  - Labels: Descriptive text next to each option
- **Container**: Light gray background, rounded corners (6px radius)
- **Spacing**: 8px between radio options

## Tab Bar
```
┌─────────────────────────────────────────────────────┐
│  ⚙️ General      ▶️ Playback                        │
├─────────────────────────────────────────────────────┤
```

### Tab Items:
1. **General Tab**
   - Icon: ⚙️ (gear SF Symbol)
   - Label: "General"
   - Active: Bold text, accent color underline

2. **Playback Tab**
   - Icon: ▶️ (play.circle SF Symbol)
   - Label: "Playback"
   - Active: Bold text, accent color underline

## Color Scheme
- **Background**: System background color (adapts to light/dark mode)
- **Text**: Primary text color (black in light mode, white in dark mode)
- **Secondary Text**: Gray (for library path)
- **Accent Color**: System accent color (blue by default)
- **Control Background**: System control background (light gray)
- **Dividers**: System separator color

## Interactions

### General Tab
1. **Choose Button Click**:
   - Opens macOS folder picker dialog
   - User selects a folder
   - App creates/uses MusicPlayer.library bundle in that folder
   - Path display updates immediately
   - Preference saves to UserDefaults

### Playback Tab
1. **Radio Button Click**:
   - Deselects other option
   - Updates selection visually
   - Saves preference to UserDefaults immediately
   - No "Apply" or "Save" button needed

## Access Methods

### Via Menu
```
Menu Bar > MusicPlayer > Settings...
```

### Via Keyboard
```
Cmd + ,
```

## Behavior

### Window Management
- Modal window (stays on top while open)
- Can be closed with Cmd+W or red close button
- Reopens to last selected tab
- Only one preferences window can be open at a time

### Preference Persistence
- Changes save immediately (no Apply button)
- Persisted to UserDefaults
- Restored on app restart
- Affects app behavior in real-time

## Accessibility
- Full keyboard navigation support
- VoiceOver compatible
- High contrast mode support
- Respects system font size settings
