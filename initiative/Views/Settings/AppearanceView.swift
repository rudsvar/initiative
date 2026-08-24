import SwiftUI

/// Theme picker. Every option is drawn in its own colors rather than described,
/// because a palette is the one kind of setting where the label genuinely can't
/// tell you what you're choosing — and the selection applies immediately, so the
/// screen behind the picker is itself the preview.
struct AppearanceView: View {
    @Bindable var controller: ThemeController

    var body: some View {
        List {
            ForEach(ThemeIdentifier.allCases) { theme in
                Button {
                    controller.selection = theme
                } label: {
                    ThemeOptionRow(theme: theme, isSelected: controller.selection == theme)
                }
                .cardRowStyle(isHighlighted: controller.selection == theme)
                .cardRowLayout()
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .themedScreen()
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ThemeOptionRow: View {
    let theme: ThemeIdentifier
    let isSelected: Bool

    private var palette: ThemePalette { theme.palette }

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text(theme.displayName)
                    .font(Theme.Typography.rowTitle)
                    .foregroundColor(Theme.textPrimary)

                Text(theme.tagline)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                swatch
            }
            // Claim the full row width explicitly. Left to negotiate, the column
            // is sized by the fixed-width swatch strip below it and the taglines
            // wrap at different points from row to row.
            .frame(maxWidth: .infinity, alignment: .leading)

            // Reserved space either way, so picking a theme doesn't reflow the
            // rows around it.
            Image(systemName: "checkmark")
                .font(Theme.Typography.iconControl)
                .foregroundColor(isSelected ? Theme.accent : .clear)
                .frame(width: 16)
        }
    }

    /// A miniature of the palette in the order it's actually experienced: the
    /// page, a card on it, the accent that marks one thing, then the condition
    /// hues that have to stay clear of that accent.
    private var swatch: some View {
        HStack(spacing: 0) {
            chip(palette.background)
            chip(palette.surface)
            chip(palette.surfaceRaised)
            chip(palette.accent)
            chip(palette.conditionSensory)
            chip(palette.conditionMental)
            chip(palette.conditionDisabling)
            chip(palette.conditionOngoing)
        }
        .frame(height: 22)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .stroke(Theme.border.opacity(0.5), lineWidth: Theme.hairline)
        )
    }

    private func chip(_ color: Color) -> some View {
        Rectangle()
            .fill(color)
            .frame(width: 26)
    }
}

#Preview {
    NavigationStack {
        AppearanceView(controller: ThemeController())
    }
}
