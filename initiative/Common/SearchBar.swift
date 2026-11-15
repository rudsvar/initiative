import SwiftUI

extension View {
    /// The system's own search field — not a custom-built bar. It stays
    /// expanded as a text field the user types into, not a collapsed magnifying
    /// glass that opens on tap. The owner asked for the text bar on the
    /// Creatures and Encounters lists, so this deliberately does not use
    /// `.searchToolbarBehavior(.minimize)`, which collapses it to an icon.
    ///
    /// `.searchable` alone is native on every supported iOS version.
    ///
    /// `isVisible` is for the case where there's nothing to search yet — an
    /// empty library skips search entirely rather than offering to filter
    /// nothing.
    @ViewBuilder
    func appSearchable(text: Binding<String>, prompt: String, isVisible: Bool = true) -> some View {
        if isVisible {
            self.searchable(text: text, prompt: prompt)
        } else {
            self
        }
    }
}
