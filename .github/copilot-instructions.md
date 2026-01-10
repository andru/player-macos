Architectural and development guidelines follow. In particular note:

- App targets macOS 13+. Check your work for use of depreciated APIs. Use async/await
- **Pre-MVP**: the database is **ephemeral**; update the **v1 migration in place**
- **Post-MVP**: migrations must be **rigorous** and lossless


# App Architecture Context (macOS-first Music Player)

## Overview
This project is a **macOS-first** native Swift/SwiftUI music player and catalogue manager (targeting macOS 13+), with an **iOS/iPadOS companion** focused on playback and lightweight interactions (plays/likes), not deep catalogue management.

The app is **local-first** and designed to scale toward **500k+ tracks**. It supports **heavy mutation** of the music library, including **writing updated metadata back to audio files**, while keeping **domain models immutable** (treated as snapshots).

The app is **sandboxed on macOS** and uses **security-scoped bookmarks** to access user-selected files and folders. The library does **not** require files to live in a single managed directory (that is only a suggested default). Users can import files from anywhere, including removable media. Files may move, and the app will later support **auto-relocation** to recover references.

---

## Architectural Style

### Feature slices
The codebase is organised into **feature slices** (e.g. Library, Albums, Songs, Queue, Preferences).

Each slice owns:
- A `SliceDependencies` struct (only what the feature needs)
- Feature-specific **queries** and **read models (DTOs)** for UI
- Feature root views and view models

Slices must **not**:
- Import GRDB directly
- Reach into global services or the database except through injected dependencies

---

### Composition root: AppContainer
A single `AppContainer` acts as the **composition root** and is injected once at the app root via `@EnvironmentObject`.

Responsibilities:
- Initialise long-lived infrastructure:
  - Database (`AppDatabase` / GRDB)
  - Repositories and query implementations
  - Core services (audio playback, library coordination, file/bookmark access, job runner)
- Assemble dependency structs (`FeatureDeps`, `SliceDependencies`)
- Gate readiness with a state machine (e.g. `.idle / .ready(FeatureDeps)`), so views never assume dependencies exist prematurely

---

### Dependency propagation
- `@EnvironmentObject` is used **only** for:
  - `AppContainer`
  - Other always-available global state (e.g. preferences)
- **Feature dependencies are passed explicitly** at feature boundaries (feature root views)
- Leaf views should be pure UI and must not look up dependencies from the environment

Pattern:
```
AppContainer (env)
└─ RootView (switch on container.state)
    └─ FeatureRootView(deps: SliceDependencies)
        └─ Child views (pure UI)
```

---

## MVVM conventions
- View models live at the **feature root** level and are owned by the feature root view (`@StateObject`).
- View models:
  - Receive dependencies via initializer (or one-time configuration)
  - Own async loading, caching, and transformation logic
  - Expose simple `@Published` state for rendering
- Child views are stateless or minimally stateful and render view model output only.
- Async loading is driven by SwiftUI lifecycle using `.task {}` or `.task(id:)`.
- Selection-driven detail views load data via `.task(id:)` and explicitly model `idle / loading / loaded / error`.

---

## Concurrency model
- **Swift concurrency (`async/await`) by default**
- Combine may be used only for niche streaming or observation use cases
- Avoid accessing `@EnvironmentObject` in `init`
- Services are references, not bindable state; state lives in view models or persisted stores

---

## Persistence and data layering

### Domain vs read models
- Domain models live in a shared `Models/` layer and are treated as **immutable snapshots**
- Feature slices define **read models / DTOs** optimized for UI needs

### GRDB isolation
- GRDB implementations live in a dedicated `GRDB/` layer:
  - Repositories for domain persistence
  - Query implementations for feature read models
- Feature DTOs gain `FetchableRecord` / `Decodable` conformance via **extensions in the GRDB layer**
- Views and view models never import GRDB

---

### Development vs production migrations
- **Pre-MVP**: the database is **ephemeral**; update the **v1 migration in place**
- **Post-MVP**: migrations must be **rigorous** and lossless

---

### UI state persistence
- Semi-transient UI state may use non-GRDB persistence
- Any UI state that becomes part of the user’s **collection** (e.g. collection order, layout, sort preferences) must persist to **GRDB**

---

## Library and file model
- A `Recording` can have **multiple `DigitalFile`s** (e.g. FLAC + MP3 encodes, different digitisations)
- Most users will not interact with this directly; advanced users may
- Each `DigitalFile` stores:
  - A file URL reference
  - A **security-scoped bookmark**
- Files may be missing or offline (e.g. removable media); all such states must be handled and surfaced to the user

### Metadata write-back
- Support common tag standards (ID3, Vorbis, MP4, etc.)
- When the app writes metadata, the database must be updated in the same logical operation
- External file changes are handled via **progressive rescans**
- Filesystem monitoring is optional but must not be required for correctness

---

## Search and performance
- Target: **snappy search-as-you-type** at large scale (500k+ tracks)
- MVP approach: **SQLite FTS5** via GRDB
- Search must be **diacritic-insensitive** (e.g. `björk` == `bjork`)
- Post-MVP: indexed projections, additional search tables, and extra dependencies are acceptable

---

## Error handling
- Crashes are to be avoided outside development builds
- User-facing failures must include:
  - A clear message
  - A stable **error code**
- Filesystem failures (permissions, missing files, bookmark issues) must be explicit and recoverable where possible

---

## Background-capable job system (macOS)
All long-running work must use a **persistent, resumable job runner**, including:
- Imports and rescans
- Metadata/tag write-back
- Relocation and integrity checks

Jobs must:
- Have durable identity and persisted state (`queued / running / paused / failed / completed`)
- Report progress
- Be idempotent and resumable
- Handle sandbox/bookmark access correctly
- Surface failures with user-visible error codes and messages

---

## iOS/iPadOS companion (future direction)
- Mostly read-only consumer of the catalogue
- Can feed back likes and play counts (not real-time)
- Future direction:
  - User selects tracks on macOS to make available offline on device
  - Files are copied to the device
  - Optional streaming of the rest later (complex; to be evaluated, including iCloud constraints)

---

## Integrations (planned)
Planned integrations include:
- Scrobbling
- MusicBrainz import
- Potential fediverse/open streaming or video integrations

Direct service usage is acceptable initially (no third-party plugin system expected), but boundaries should remain clean to avoid tight coupling to vendor SDKs.
