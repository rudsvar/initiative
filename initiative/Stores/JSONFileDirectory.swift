import Foundation

/// A folder of JSON files, one per item, named by the item's id. The storage under
/// `SessionStore`, `PresetStore` and `EncounterStore`, so all three read, write and
/// delete the same way. A file that can't be read or decoded is skipped, never
/// deleted: it may be a format this build doesn't know yet.
struct JSONFileDirectory<Item: Codable & Identifiable> where Item.ID == UUID {
    let url: URL

    init(url: URL) {
        self.url = url
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    private func fileURL(for id: UUID) -> URL {
        url.appendingPathComponent("\(id.uuidString).json")
    }

    func readAll() -> [Item] {
        guard let files = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) else {
            return []
        }
        return files.compactMap(Self.decode)
    }

    func read(id: UUID) -> Item? {
        Self.decode(fileURL(for: id))
    }

    func write(_ item: Item) {
        guard let data = try? JSONEncoder().encode(item) else { return }
        // Made again if something removed it since launch.
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        try? data.write(to: fileURL(for: item.id))
    }

    func remove(id: UUID) {
        try? FileManager.default.removeItem(at: fileURL(for: id))
    }

    private static func decode(_ file: URL) -> Item? {
        guard let data = try? Data(contentsOf: file) else { return nil }
        return try? JSONDecoder().decode(Item.self, from: data)
    }
}
