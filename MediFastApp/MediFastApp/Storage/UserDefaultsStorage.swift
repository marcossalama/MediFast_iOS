import Foundation

/// Concrete storage backed by `UserDefaults` with JSON encoding.
struct UserDefaultsStorage: StorageProtocol {
    private let defaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        self.encoder = enc

        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        self.decoder = dec
    }

    func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw StorageError.decodingFailed(underlying: error)
        }
    }

    func save<T: Codable>(_ value: T, forKey key: String) throws {
        do {
            let data = try encoder.encode(value)
            defaults.set(data, forKey: key)
        } catch {
            throw StorageError.encodingFailed(underlying: error)
        }
    }

    func remove(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
}

