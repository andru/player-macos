import SwiftUI

struct RootView: View {
    @EnvironmentObject var container: AppContainer
    
    var body: some View {
        HStack {
            switch container.state {
            case .booting:
                ProgressView("Booting up…")
            case .idle:
                ProgressView("Loading…")
            case .opening:
                ProgressView("Opening library…")
                
            case .ready(let deps):
                ContentView()
                    
            case .failed(let error):
                LibraryErrorView(
                    error: error
//                    , onRetry: {
//                        Task {
//                            await ...
//                        }
//                    }
                )
            case .error(let error):
                LibraryErrorView(
                    error: error
//                    , onRetry: {
//                        Task {
//                            await ...
//                        }
//                    }
                )
            }
        }
    }
}
