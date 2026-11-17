import SwiftUI

/// A library list's section heading ("Your creatures", "All encounters"), as a
/// plain row: a `.plain` List pins a `Section` header so it floats over the
/// scroll, which a page-local label should not do. Every library and picker uses
/// it, with the same rule: "Your …" is always shown, with `emptyHint` under it
/// when the owner has none yet, so a new user sees where their own will go.
struct LibrarySectionLabel: View {
    let title: String
    /// Shown under the heading when there is nothing of the owner's yet.
    var emptyHint: String?

    var body: some View {
        Text(title)
            .sectionLabel()
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        if let emptyHint {
            Text(emptyHint)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.textTertiary)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }
    }
}
