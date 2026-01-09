import SwiftUI

struct RootView: View {
    @EnvironmentObject var container: AppContainer
    
    var body: some View {
        HStack {
            switch container.state {
                
            case .idle:
                //                OpenLibraryView(
                //                    onOpen: {
                //                        Task {
                //                            await container.openLibrary()
                //                        }
                //                    }
                //                )
                ProgressView("Loading…")
            case .opening:
                ProgressView("Opening library…")
                
            case .ready(let deps):
                ContentView()
                    
                
            case .error(let error):
                LibraryErrorView(
                    error: error
//                    , onRetry: {
//                        Task {
//                            await container.openLibrary()
//                        }
//                    }
                )
            }
        }
    }
}
