import Foundation

/// Loads the bundled SRD 5.2.1 stat blocks (`Data/srd-creatures.json`).
///
/// Read-only: nothing here writes, and nothing is copied into a session. The
/// numbers the built-in creature list uses (hit points, armor class, initiative
/// bonus) must match the entries here; `SRDCatalogTests` checks that.
enum SRDCatalog {

    struct Document: Codable {
        let source: String
        let changes: String
        let creatures: [StatBlock]
    }

    static func load(from url: URL) throws -> [StatBlock] {
        try JSONDecoder().decode(Document.self, from: Data(contentsOf: url)).creatures
    }

    /// The stat blocks shipped in the app bundle. Empty if the file is missing,
    /// which the tests would catch before a build ships.
    static let bundled: [StatBlock] = {
        guard let url = Bundle.main.url(forResource: "srd-creatures", withExtension: "json") else {
            return []
        }
        return (try? load(from: url)) ?? []
    }()

    private static let byName: [String: StatBlock] = {
        Dictionary(bundled.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })
    }()

    /// The stat block with this name, if there is one. A lookup rather than a scan:
    /// every library row asks, on every redraw.
    static func block(named name: String) -> StatBlock? {
        byName[name]
    }

    /// The stat block for a combatant. Copies added together are numbered
    /// ("Goblin 2", see `CombatSession.addCombatants`), so a trailing number is
    /// dropped when the full name finds nothing. No stat block name ends in one.
    static func block(forCombatantNamed name: String) -> StatBlock? {
        if let exact = block(named: name) { return exact }
        guard let space = name.lastIndex(of: " "),
              !name[name.index(after: space)...].isEmpty,
              name[name.index(after: space)...].allSatisfy(\.isNumber) else { return nil }
        return block(named: String(name[..<space]))
    }
}
