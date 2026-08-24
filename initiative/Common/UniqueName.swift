import Foundation

/// Names for copies made from a built-in creature or encounter.
///
/// Built-in content is read-only, so "customise this one" means "make a copy and
/// edit that". The copy needs a name that's obviously derived from the original
/// and doesn't collide with anything already saved — including a previous copy,
/// since making two is a perfectly ordinary thing to do.
enum UniqueName {
    /// `"Goblin"` → `"Goblin Copy"`, then `"Goblin Copy 2"`, `"Goblin Copy 3"`…
    ///
    /// Comparison is case-insensitive, matching how the stores themselves treat
    /// names — a "goblin copy" already on disk still counts as taken.
    static func forCopy(of name: String, avoiding existing: [String]) -> String {
        let taken = Set(existing.map { $0.lowercased() })
        let base = "\(name.trimmingCharacters(in: .whitespaces)) Copy"

        guard taken.contains(base.lowercased()) else { return base }
        // Starts at 2 because the unsuffixed name is conceptually the first copy.
        var suffix = 2
        while taken.contains("\(base) \(suffix)".lowercased()) {
            suffix += 1
        }
        return "\(base) \(suffix)"
    }
}
