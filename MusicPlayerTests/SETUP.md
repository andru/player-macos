# Adding Tests to MusicPlayer

## Manual Setup Instructions

Since the test target needs to be added to the Xcode project file, follow these steps:

### Option 1: Using Xcode (Recommended)

1. Open `MusicPlayer.xcodeproj` in Xcode
2. In the Project Navigator, select the project file (top item)
3. Click the "+" button at the bottom of the targets list
4. Select "Unit Testing Bundle" under macOS
5. Name it "MusicPlayerTests"
6. Set the "Target to be Tested" to "MusicPlayer"
7. Click "Finish"
8. Delete the auto-generated test file (if any)
9. Add the test files from the `MusicPlayerTests` folder:
   - Right-click on the test target
   - Choose "Add Files to MusicPlayerTests..."
   - Select `LibraryManagerSecurityBookmarkTests.swift`
   - Ensure "MusicPlayerTests" target is checked
10. Run tests with Cmd+U

### Option 2: Swift Package Manager (Alternative)

If you prefer using SPM for testing, create a `Package.swift` file:

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MusicPlayer",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "MusicPlayerLib", targets: ["MusicPlayerLib"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MusicPlayerLib",
            path: "MusicPlayer",
            exclude: ["Info.plist", "Assets.xcassets", "MusicPlayer.entitlements"]
        ),
        .testTarget(
            name: "MusicPlayerTests",
            dependencies: ["MusicPlayerLib"],
            path: "MusicPlayerTests"
        )
    ]
)
```

Then run: `swift test`

### Option 3: Command Line Build

You can also add the test target via command line:

```bash
# This requires xcodegen or similar tools
# See: https://github.com/yonaskolb/XcodeGen
```

## Verifying Tests Work

Once the test target is set up, you can run the tests:

```bash
# In Xcode: Cmd+U
# Or via command line:
xcodebuild test -project MusicPlayer.xcodeproj -scheme MusicPlayerTests
```

## Test Files Created

- `MusicPlayerTests/LibraryManagerSecurityBookmarkTests.swift` - Main test file
- `MusicPlayerTests/Info.plist` - Test bundle configuration
- `MusicPlayerTests/README.md` - Test documentation

## What the Tests Verify

The security bookmark tests ensure:
1. ✓ Bookmarks are created when directories are imported
2. ✓ Multiple directory bookmarks can be stored
3. ✓ Bookmarks can be restored on app relaunch
4. ✓ Stale bookmarks are detected
5. ✓ Bookmark refresh updates UserDefaults correctly
6. ✓ Recursive directory scanning finds all music files
7. ✓ Security-scoped resource access is properly managed
8. ✓ Created bookmarks are valid security-scoped bookmarks
