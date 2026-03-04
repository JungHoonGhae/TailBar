import Foundation

actor ResponseCache {
    private struct Entry {
        let data: Any
        let timestamp: Date
    }

    private var storage: [String: Entry] = [:]
    private let ttl: TimeInterval

    init(ttl: TimeInterval = 2.0) {
        self.ttl = ttl
    }

    func get<T>(_ key: String) -> T? {
        guard let entry = storage[key] else { return nil }
        guard Date().timeIntervalSince(entry.timestamp) < ttl else {
            storage.removeValue(forKey: key)
            return nil
        }
        return entry.data as? T
    }

    func set(_ key: String, value: Any) {
        storage[key] = Entry(data: value, timestamp: Date())
    }

    func invalidate(_ key: String) {
        storage.removeValue(forKey: key)
    }

    func invalidateAll() {
        storage.removeAll()
    }
}
