import SwiftUI

/// A library row: one card that opens the entry, with a Clone button inside it on
/// the right, split by a hairline. Creatures, characters and encounters all use
/// this, so copying works the same everywhere and a new user can see it without
/// hunting for it. The Clone button takes only its own width; the rest is the name.
struct CloneableRow<Label: View>: View {
    let open: () -> Void
    let clone: () -> Void
    @ViewBuilder let label: () -> Label

    var body: some View {
        HStack(spacing: 0) {
            Button(action: open, label: label)
                .buttonStyle(RowSegmentStyle())
            Rectangle()
                .fill(Theme.border.opacity(0.5))
                .frame(width: Theme.hairline)
            Button(action: clone) {
                Image(systemName: "doc.on.doc")
                    .font(Theme.Typography.iconInline)
                    .foregroundColor(Theme.textSecondary)
            }
            .buttonStyle(RowSegmentStyle(expands: false))
            .accessibilityLabel("Clone")
        }
        .background(Theme.surface)
        .cardOutline()
        .cardRowLayout()
    }
}

/// One tappable part of a card: padded, and tinted while pressed.
private struct RowSegmentStyle: ButtonStyle {
    /// The name segment takes all the room left; the Clone segment only its icon.
    var expands = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(Theme.Spacing.md)
            .frame(maxWidth: expands ? .infinity : nil, maxHeight: .infinity, alignment: .leading)
            .background(configuration.isPressed ? Theme.accent.opacity(0.15) : Color.clear)
            .contentShape(Rectangle())
    }
}
