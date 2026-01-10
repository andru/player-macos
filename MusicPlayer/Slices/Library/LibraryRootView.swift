import SwiftUI

struct LibraryRootView: View {
    @EnvironmentObject var container: AppContainer
    // Make `body` available for the deployment target (macOS 13+). If any
    // APIs used inside require macOS 14+, guard with `if #available` there.
    var body: some View {
        LibraryView(vm: LibraryViewModel(deps: container.featureDeps.library, repos: container.repositories))
    }
}
