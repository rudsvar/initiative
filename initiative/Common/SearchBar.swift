import SwiftUI

extension View {
    /// The system's own search field — not a custom-built bar. On iOS 26+
    /// this is `.searchable` plus `.searchToolbarBehavior(.minimize)`, which
    /// is exactly what turns it into the collapsed glass search icon that
    /// expands into a floating glass field on tap, the same pattern every
    /// stock iOS 26 app uses (Notes, Files, Photos). A hand-built bar was
    /// tried here first — full-width, permanently expanded, docked at the
    /// bottom — and it read as too wide and too heavy next to how search
    /// actually looks on iOS 26; the system component already gets both the
    /// sizing and the glass material right for free.
    ///
    /// Below iOS 26, `.searchToolbarBehavior` doesn't exist, so this falls
    /// back to plain `.searchable` — still fully native, just not minimized.
    ///
    /// `isVisible` is for the case where there's nothing to search yet — an
    /// empty library skips search entirely rather than offering to filter
    /// nothing.
    @ViewBuilder
    func appSearchable(text: Binding<String>, prompt: String, isVisible: Bool = true) -> some View {
        if isVisible {
            if #available(iOS 26.0, *) {
                self
                    .searchable(text: text, prompt: prompt)
                    .searchToolbarBehavior(.minimize)
            } else {
                self.searchable(text: text, prompt: prompt)
            }
        } else {
            self
        }
    }
}
