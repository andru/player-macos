import SwiftUI

struct LibraryErrorView: View {
    var error: any Error
    
    var body: some View {
        Text(error.localizedDescription)
            .foregroundColor(.red)
            .padding()
    }
}

