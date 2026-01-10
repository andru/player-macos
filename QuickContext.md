# App Architecture Summary
A quick high-level overview of the app's architecture.

## 1) Feature Slices
The app is organised into **feature slices** (e.g. Library, Songs, Albums, Queue).

Each slice owns:
- A `SliceDependencies` struct (only what the feature needs)
- Feature-specific **queries** and **read models (DTOs)** for views
- Feature-root views and view models

Feature slices do **not**:
- Import or depend directly on GRDB
- Reach into global services or the database without going through dependencies

---

## 2) AppContainer (Composition Root)
There is a single `AppContainer` acting as the **composition root**.

Responsibilities:
- Initialise long-lived infrastructure:
  - Database (`AppDatabase`)
  - GRDB repositories and query implementations
  - Core services (e.g. `AudioPlayerService`, `AppLibraryService`)
- Assemble these into **dependency structs** (`FeatureDeps`, `SliceDependencies`)
- Expose readiness via a `state` enum (e.g. `.idle / .ready(FeatureDeps)`)

`AppContainer` is injected once at the app root using `@EnvironmentObject`.

Important constraints:
- `AppContainer` is **stable** (exists for the app lifetime)
- Potentially unavailable resources (library/bookmarks/db) are gated via state, not placeholders
- Views must not assume dependencies exist unless state is `.ready`

---

## 3) Dependency Propagation
- `@EnvironmentObject` is used **only** for:
  - `AppContainer`
  - Other always-available global state (e.g. preferences)
- **Feature dependencies are passed explicitly** at feature boundaries (root views)
- Leaf views do not reach into `AppContainer`

Pattern:
```
AppContainer (env)
└─ RootView (switch on container.state)
    └─ FeatureRootView(deps: SliceDependencies)
        └─ Child views (pure UI)
```

---

## 4) MVVM Placement
- **ViewModels live at the feature root level**
- Feature root views:
  - Read dependencies
  - Create and own `@StateObject` view models
  - Trigger initial loading via `.task {}` or `.task(id:)`
- Child views are:
  - Stateless or minimally stateful
  - Driven entirely by view model output
  - Free of environment lookups

View models:
- Receive dependencies via initializer or one-time `configure`
- Own async loading, caching, and transformation logic
- Expose simple `@Published` state to views

---

## 5) Data Loading & Lifecycle
- User interaction (e.g. selecting an album) updates **selection state**
- Detail views load data using `.task(id:)`, tied to the selected ID
- Loading state is modelled explicitly (idle / loading / loaded / error)
- SwiftUI view lifecycle drives async work; view models guard idempotence

---

## 6) GRDB Integration
- Domain models live in a shared `Models/` layer
- Feature slices define **read models** (e.g. `AlbumRow`, `TrackRow`) for UI needs
- GRDB implementations live in a separate `GRDB/` layer:
  - GRDB repositories for domain persistence
  - GRDB query implementations for feature queries
- Feature DTOs may gain `FetchableRecord / Decodable` conformance via **extensions in the GRDB layer**
- Views and view models never import GRDB

---

## 7) SwiftUI Best Practices Observed
- No access to `@EnvironmentObject` in `init`
- No bindings for service objects (services are references, not state)
- `guard` used for early exits, especially in loops
- Complex view bodies are broken into subviews to avoid type-checker blowups
- `ForEach` prefers indices over `enumerated()` for performance and type stability

---

## Mental Model
- **EnvironmentObject = lookup + reactivity, not readiness**
- **Dependencies are real or absent — never placeholders**
- **Feature roots are the boundary between wiring and UI**
- **Views render state; view models fetch state; container wires state**
