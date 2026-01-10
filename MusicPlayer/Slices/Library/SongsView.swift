import SwiftUI

struct SongsView: View {
    @EnvironmentObject var preferences: PreferencesService
    @EnvironmentObject var container: AppLibraryService
    let vm: LibraryViewModel
    
    var body: some View {
        TrackTableView(vm: vm)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppLibraryService())
        .environmentObject(PreferencesService())
}
