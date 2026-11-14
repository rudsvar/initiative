import Foundation

/// How the two browsable lists — Creatures and Encounters — decide what to show
/// and in what order.
///
/// Both screens present the same kind of thing (a saved library that mixes what
/// shipped with the app and what the user has built up), so they get the same
/// treatment from one place rather than each inventing its own: filter by the
/// search query, then split into the user's own entries above the built-in ones.
/// Keeping it here rather than in the views is also what makes it testable — a
/// view body is the one place this logic couldn't be checked.
enum ListSections {

    // MARK: - Search

    /// Whether `query` matches an item, given every string worth searching in it.
    ///
    /// Terms are ANDed and may match different fields, so "goblin boss" finds the
    /// Goblin Boss creature and "troll boar" finds the Bridge Troll encounter
    /// (whose name contains neither word — its *lineup* does).
    ///
    /// Matching is `localizedStandardContains`, which is the case- and
    /// diacritic-insensitive comparison Apple uses for user-facing search; a
    /// plain `contains` would fail on "Wyrm" vs "wyrm" and on any accented name.
    static func matches(query: String, in fields: [String]) -> Bool {
        let terms = query.split(whereSeparator: \.isWhitespace)
        guard !terms.isEmpty else { return true }
        return terms.allSatisfy { term in
            fields.contains { $0.localizedStandardContains(term) }
        }
    }

    /// Same as `matches`, but terms are ORed instead of ANDed — any one term
    /// matching any one field is enough. Used for encounter search rather
    /// than requiring every typed word to match: an encounter's fields are a
    /// name plus a whole lineup of creature names, and wanting "goblin" *or*
    /// "troll" is a more common search there than wanting every word to land.
    static func matchesAny(query: String, in fields: [String]) -> Bool {
        let terms = query.split(whereSeparator: \.isWhitespace)
        guard !terms.isEmpty else { return true }
        return terms.contains { term in
            fields.contains { $0.localizedStandardContains(term) }
        }
    }

    // MARK: - Origin

    /// Splits a list into the user's own entries and the ones that shipped with
    /// the app, preserving the incoming order within each group.
    static func split<T>(_ items: [T], isBuiltIn: (T) -> Bool) -> (mine: [T], builtIn: [T]) {
        var mine: [T] = []
        var builtIn: [T] = []
        for item in items {
            if isBuiltIn(item) {
                builtIn.append(item)
            } else {
                mine.append(item)
            }
        }
        return (mine, builtIn)
    }
}

// MARK: - What each screen searches, and what counts as built-in

extension CreaturePreset {
    /// Only the name — it's the only text a creature has.
    var searchableText: [String] { [name] }

    /// Identity is by **name**, not by a stored flag: a preset the user renamed
    /// has become theirs, while one they edited the stats of but kept the name of
    /// is still recognisably the built-in creature. That also means no migration
    /// of the on-disk format, and nothing to get out of step if the default
    /// roster changes.
    var isBuiltIn: Bool { DefaultContent.creature(named: name) != nil }
}

extension Encounter {
    /// The encounter's name *and* every creature in it, so "wight" finds The
    /// Crypt Stirs. Searching a prepared encounter by what's in it is the more
    /// likely question at the table than searching by a name you chose months ago.
    var searchableText: [String] { [name] + entries.map(\.name) }

    var isBuiltIn: Bool {
        DefaultContent.encounters.contains { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }
    }
}
