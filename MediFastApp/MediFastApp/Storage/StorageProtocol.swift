import Foundation

/// Minimal storage abstraction for on-device persistence.
/// Keep simple to allow swapping implementations if needed.
public protocol StorageProtocol {
    func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T?
    func save<T: Codable>(_ value: T, forKey key: String) throws
    func remove(forKey key: String)
}

public enum StorageError: Error, LocalizedError {
    case encodingFailed(underlying: Error)
    case decodingFailed(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .encodingFailed(let err):
            return "Encoding failed: \(err.localizedDescription)"
        case .decodingFailed(let err):
            return "Decoding failed: \(err.localizedDescription)"
        }
    }
}

