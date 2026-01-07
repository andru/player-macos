import Foundation
import SwiftUI
import AVFoundation
import AppKit
import ImageIO
import CryptoKit

struct Collection: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var trackIDs: [UUID]

    init(id: UUID = UUID(), name: String, trackIDs: [UUID] = []) {
        self.id = id
        self.name = name
        self.trackIDs = trackIDs
    }
}
