import SwiftUI

/// A library row: the card that opens the entry, with a Clone button beside it.
/// Creatures, characters and encounters all use this, so copying works the same
/// everywhere and a new user can see it without hunting for it.
struct CloneableRow<Label: View>: View {
    let open: () -> Void
    let clone: () -> Void
    @ViewBuilder let label: () -> Label

    var body: some View {
        HStack(spacing: Theme.Spacing.xs + 2) {
            Button(action: open, label: label)
                .buttonStyle(CardRowButtonStyle())
            Button(action: clone) {
                Image(systemName: "doc.on.doc")
                    .font(Theme.Typography.iconInline)
                    .foregroundColor(Theme.textSecondary)
                    .frame(minHeight: Theme.Spacing.xl)
            }
            .buttonStyle(CardRowButtonStyle())
            .fixedSize(horizontal: true, vertical: false)
            .accessibilityLabel("Clone")
        }
        .cardRowLayout()
    }
}
