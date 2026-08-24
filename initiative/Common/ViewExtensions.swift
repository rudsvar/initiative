import SwiftUI

extension View {
    /// Full-screen themed backdrop. Prefer this over a bare `Theme.background`
    /// rectangle so every screen picks up the same warm falloff.
    func themedScreen() -> some View {
        self.background(Theme.backgroundGradient.ignoresSafeArea())
    }

    /// The card look used for every list row across the app (combatant rows,
    /// creature/encounter/session rows). One shared definition so every list
    /// stays visually consistent instead of each screen inventing its own chrome.
    ///
    /// The highlighted state (current-turn combatant) is carried by three things
    /// at once — a lift to the top surface level, an accent outline, and a solid
    /// accent bar down the leading edge — rather than by a tinted wash. The bar
    /// is what makes the active row findable while scanning down the initiative
    /// column, which a background tint alone doesn't do.
    func cardRowStyle(isHighlighted: Bool = false) -> some View {
        self
            .padding(Theme.Spacing.md)
            .background(isHighlighted ? Theme.surfaceRaised : Theme.surface)
            .overlay(alignment: .leading) {
                if isHighlighted {
                    Rectangle()
                        .fill(Theme.accent)
                        .frame(width: 3)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .stroke(
                        isHighlighted ? Theme.accent.opacity(0.55) : Theme.border.opacity(0.5),
                        lineWidth: Theme.hairline
                    )
            )
    }

    /// The standard list-row chrome that goes with `cardRowStyle` — clears the
    /// system row background and separators so the card is the only visible
    /// container. Always paired with `cardRowStyle` on `List` rows.
    func cardRowLayout() -> some View {
        self
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(
                top: Theme.Spacing.xs + 2,
                leading: Theme.Spacing.sm,
                bottom: Theme.Spacing.xs + 2,
                trailing: Theme.Spacing.sm
            ))
            .listRowBackground(Color.clear)
    }

    /// A grouped block of related controls on a detail screen — one step up from
    /// the page, so a screen reads as a few distinct areas rather than a single
    /// run of fields.
    func sectionCard() -> some View {
        self
            .padding(Theme.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .stroke(Theme.border.opacity(0.4), lineWidth: Theme.hairline)
            )
    }

    /// Text input chrome — the raised surface plus a hairline outline. Extracted
    /// because it was copy-pasted at every field on the detail screen, which is
    /// how field styling drifts apart one edit at a time.
    func fieldStyle(width: CGFloat? = nil) -> some View {
        self
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .frame(width: width)
            .background(Theme.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                    .stroke(Theme.border.opacity(0.6), lineWidth: Theme.hairline)
            )
    }
}

extension Text {
    /// Small all-caps label above an individual field. The letter-spacing is the
    /// point: at caption size, tracked uppercase reads as a deliberate label
    /// rather than as undersized body text.
    func sectionLabel() -> some View {
        self
            .font(Theme.Typography.label)
            .textCase(.uppercase)
            .tracking(0.9)
            .foregroundColor(Theme.textTertiary)
    }

    /// The title of a whole card ("Health", "Active Effects"). Deliberately a
    /// different *kind* of type from `sectionLabel` — serif and larger, not just
    /// a brighter version of the same caps — so a card's title never reads as
    /// merely one more field label inside it.
    func cardHeading() -> some View {
        self
            .font(Theme.Typography.rowTitle)
            .foregroundColor(Theme.textPrimary)
    }
}
