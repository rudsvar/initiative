import SwiftUI

/// Owns which `ThemePalette` is currently in force, and remembers it across
/// launches.
///
/// This is a singleton read through `Theme`'s static accessors rather than an
/// environment value, and that's the whole trick behind theme selection here:
/// because it's `@Observable` and SwiftUI tracks every observable property read
/// during a `body` evaluation — no matter how many static accessors the read
/// travels through — a view that says `Theme.surface` is automatically
/// re-rendered when the selection changes. The alternative (an
/// `@Environment(\.themePalette)` value) would have meant editing every one of
/// the app's views to thread it through, for the same result.
@Observable
final class ThemeController {

    /// The instance `Theme` reads. Tests construct their own against a scratch
    /// `UserDefaults` rather than mutating this one.
    static let shared = ThemeController()

    static let storageKey = "selectedTheme"

    /// Used when nothing has been chosen yet, and by "Reset" in the picker.
    static let defaultSelection: ThemeIdentifier = .tavernCandlelight

    @ObservationIgnored private let defaults: UserDefaults

    var selection: ThemeIdentifier {
        didSet {
            guard selection != oldValue else { return }
            defaults.set(selection.rawValue, forKey: Self.storageKey)
            // The nav bar is UIKit and can't observe anything — see
            // Theme.applyNavigationBarAppearance().
            Theme.applyNavigationBarAppearance()
        }
    }

    var palette: ThemePalette { selection.palette }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // An unrecognised stored value (a theme removed in a later version)
        // falls back rather than failing: a stale preference must never be able
        // to stop the app from drawing.
        let stored = defaults.string(forKey: Self.storageKey)
        self.selection = stored.flatMap(ThemeIdentifier.init(rawValue:)) ?? Self.defaultSelection
    }
}
