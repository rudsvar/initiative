import Foundation

/// The name a clone is saved under. There is no default: the owner types it,
/// so a copy never appears as "Goblin Copy" without them choosing that.
///
/// Names match the way the stores look names up: case-insensitive, with
/// surrounding spaces ignored.
enum CloneName {
    static func isValid(_ name: String, avoiding existing: [String]) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        return !existing.contains { $0.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }
    }
}
