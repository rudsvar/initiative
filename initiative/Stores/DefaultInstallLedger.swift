import Foundation

/// Remembers which pieces of default content have ever been installed, so that
/// defaults can be **added to** what a person already has rather than being an
/// all-or-nothing first-launch event.
///
/// The problem this solves: seeding "only if the store is empty" means a default
/// added in a later version never reaches anyone who has already used the app —
/// their store isn't empty, so seeding never runs again. Keying off "is it
/// missing right now?" instead would fix that but reintroduce a worse bug:
/// anything the user deliberately deleted would silently come back on the next
/// launch.
///
/// A ledger of what has *ever* been offered separates the two. Something absent
/// from the ledger is genuinely new and gets installed; something in the ledger
/// but not in the store was deleted on purpose and stays gone. Only the explicit
/// "Restore Defaults" action overrides that.
///
/// Names are the identity, lowercased — ids can't be, since a default the user
/// has edited is still "their Goblin", and re-installing a second one under a new
/// id is exactly what this is meant to avoid.
struct DefaultInstallLedger {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults, key: String) {
        self.defaults = defaults
        self.key = key
    }

    var installedNames: Set<String> {
        Set(defaults.stringArray(forKey: key) ?? [])
    }

    func markInstalled(_ names: [String]) {
        guard !names.isEmpty else { return }
        let merged = installedNames.union(names.map { $0.lowercased() })
        defaults.set(Array(merged).sorted(), forKey: key)
    }

    func contains(_ name: String) -> Bool {
        installedNames.contains(name.lowercased())
    }
}
