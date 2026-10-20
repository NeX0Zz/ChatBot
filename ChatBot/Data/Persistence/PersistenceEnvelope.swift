/// Versioned wrapper for persisted lists so the format can be migrated later.
struct PersistenceEnvelope<Item: Codable & Sendable>: Codable, Sendable {
    static var currentVersion: Int { 1 }

    let schemaVersion: Int
    let items: [Item]

    init(items: [Item]) {
        schemaVersion = Self.currentVersion
        self.items = items
    }
}
