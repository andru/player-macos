This folder is a template for a MusicPlayer `.library` bundle.

Usage:
1. Create a directory named `MyLibrary.library` in the user's chosen location.
2. Inside it, create `Contents/` and `Contents/Resources/`.
3. Copy `Contents/Info.plist` into the `Contents/` folder and the files in `Contents/Resources/` into `Contents/Resources/`.
4. Store your library data (JSON, tracks, artwork, etc.) inside `Contents/Resources/`.

Notes:
- To have Finder treat `.library` directories as packages, declare a UTI in your app's Info.plist where the UTI
  conforms to `com.apple.package` and maps to the `library` filename extension.
- The app can also include `CFBundleDocumentTypes` entries so the system associates `.library` files with this app.
