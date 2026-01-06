# MusicPlayer Tests

This directory contains unit tests for the MusicPlayer application.

## Test Files

### ViewModePreferencesTests.swift
Tests for verifying that view mode preferences (grid/thumbnail vs. list) are correctly persisted for each library view (Artists, Albums, Songs).

**Test Coverage:**
- Default view modes for each view type (Artists: grid, Albums: grid, Songs: list)
- Persistence of grid and list modes for all three views
- Independence of preferences (changing one view doesn't affect others)
- Value format validation
- Persistence across multiple reads (simulating app restarts)

## Running Tests

### Using Xcode
1. Open `MusicPlayer.xcodeproj` in Xcode
2. Select the MusicPlayerTests scheme
3. Press Cmd+U to run all tests
4. Or use Product > Test from the menu

### Using xcodebuild (Command Line)
```bash
xcodebuild test -project MusicPlayer.xcodeproj -scheme MusicPlayerTests
```

## Test Structure

Tests follow the Given-When-Then pattern for clarity:
- **Given**: Setup the test scenario
- **When**: Perform the action being tested
- **Then**: Verify the expected outcome

## Adding New Tests

When adding new tests:
1. Create a new test file in this directory following the naming convention `*Tests.swift`
2. Import XCTest and the MusicPlayer module: `@testable import MusicPlayer`
3. Follow the existing test structure and naming conventions
4. Add appropriate setup/teardown methods if needed
5. Add the test file to the MusicPlayerTests target in Xcode
