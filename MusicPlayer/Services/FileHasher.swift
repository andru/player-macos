import Foundation
import CryptoKit

/// Utility for computing content hashes of files
struct FileHasher {
    /// Compute SHA256 hash of file content
    /// - Parameter url: File URL to hash
    /// - Returns: Hex string representation of the hash
    static func computeContentHash(for url: URL) throws -> String {
        let fileData = try Data(contentsOf: url)
        let hash = SHA256.hash(data: fileData)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Compute SHA256 hash of file content, reading in chunks for large files
    /// - Parameter url: File URL to hash
    /// - Returns: Hex string representation of the hash
    static func computeContentHashStreaming(for url: URL) throws -> String {
        let bufferSize = 1024 * 1024 // 1MB buffer
        
        // Open file for reading
        guard let fileHandle = try? FileHandle(forReadingFrom: url) else {
            throw FileHasherError.unableToOpenFile
        }
        defer {
            try? fileHandle.close()
        }
        
        var hasher = SHA256()
        
        // Read file in chunks
        while autoreleasepool(invoking: {
            let data = fileHandle.readData(ofLength: bufferSize)
            if data.isEmpty {
                return false
            }
            hasher.update(data: data)
            return true
        }) {}
        
        let hash = hasher.finalize()
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

enum FileHasherError: Error {
    case unableToOpenFile
}
