import SwiftUI

extension View {
    /// Full-screen themed backdrop. Prefer this over a bare `Theme.background`
    /// rectangle so every screen picks up the same warm falloff.
    func themedScreen() -> some View {
        self.background(Theme.backgroundGradient.ignoresSafeArea())
    }

    /// The standard list-row chrome that goes with `CardRowButtonStyle` —
    /// clears the system row background and separators so the card is the
    /// only visible container. Always paired with `CardRowButtonStyle` on
    /// `List` rows.
    func cardRowLayout() -> some View {
        self
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(
                top: Theme.Spacing.xsm,
                leading: Theme.Spacing.sm,
                bottom: Theme.Spacing.xsm,
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

    /// Sizes a sheet to this view's own content height instead of a fixed
    /// `.presentationDetents` fraction (`.medium` leaves a short prompt floating
    /// in mostly empty space) — used by small popups like `TurnPromptView` and
    /// `LimitedUseEditorView` that don't warrant a full navigation screen.
    func selfSizingSheet() -> some View {
        modifier(SelfSizingSheetModifier())
    }

    /// A small popup sheet: sized to its content, on the system's own sheet
    /// material so it reads as a normal iOS sheet (a `Theme` fill looked out of
    /// place against the system-drawn sheet chrome around it). Every small popup
    /// uses this, so they all look alike.
    ///
    /// It pads the content itself, wider at the sides and bottom than a card:
    /// from iOS 26 a short sheet floats with large rounded corners, and a
    /// full-width button only `lg` from the edge has its corners cut off.
    func compactSheet() -> some View {
        self
            .padding(.horizontal, Theme.Spacing.xl)
            // Room for the drag indicator above.
            .padding(.top, Theme.Spacing.xl)
            .padding(.bottom, Theme.Spacing.xl)
            .selfSizingSheet()
            .presentationBackground(.regularMaterial)
    }

}

extension View {
    /// The card's rounded corners and hairline border, shared by every card row.
    func cardOutline(isHighlighted: Bool = false) -> some View {
        self
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .stroke(
                        isHighlighted ? Theme.accent.opacity(0.55) : Theme.border.opacity(0.5),
                        lineWidth: Theme.hairline
                    )
            )
    }
}

/// The pressable counterpart to `cardRowStyle`. A plain `Button` with
/// `.cardRowStyle()` chained on afterward has no visible feedback on tap
/// inside a `List` — that chained modifier sits outside the button's own
/// label, so the button's built-in press-dimming never touches it. This
/// folds the same background/border/highlight look into a `ButtonStyle`
/// instead, so `configuration.isPressed` can actually darken it. Use this
/// (not `.cardRowStyle()`) on every tappable row — combatant, creature,
/// encounter, session.
struct CardRowButtonStyle: ButtonStyle {
    var isHighlighted: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                configuration.isPressed
                    ? Theme.accent.opacity(0.15)
                    : (isHighlighted ? Theme.surfaceRaised : Theme.surface)
            )
            .overlay(alignment: .leading) {
                if isHighlighted {
                    Rectangle()
                        .fill(Theme.accent)
                        .frame(width: 3)
                }
            }
            .cardOutline(isHighlighted: isHighlighted)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct HeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 200
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct SelfSizingSheetModifier: ViewModifier {
    @State private var height: CGFloat = 200
    /// What the sheet reserves below its content (home indicator; from iOS 26
    /// also the floating sheet's margin). Read from the sheet, never assumed.
    @State private var bottomInset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            // Without this, the keyboard's safe-area inset shrinks the space
            // the `GeometryReader` below measures the instant a `TextField`
            // inside the sheet becomes focused — which shrinks the reported
            // height, which shrinks `presentationDetents`, which compresses
            // the sheet's own layout into overlapping controls (a Stepper
            // sliding up onto the TextField above it, in `LimitedUseEditorView`).
            // Ignoring the keyboard here keeps the measured height — and so
            // the sheet's own size — stable regardless of the keyboard; the
            // system still slides the whole sheet up to keep the focused
            // field visible, it just no longer reshapes it in the process.
            .ignoresSafeArea(.keyboard)
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: HeightPreferenceKey.self, value: proxy.size.height)
                }
            )
            .onPreferenceChange(HeightPreferenceKey.self) { height = $0 }
            // Pinned to the top: the sheet's own padding then sits where it is
            // meant to, instead of the content being centred in a sheet whose
            // usable height differs from the detent by the bottom inset.
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { bottomInset = proxy.safeAreaInsets.bottom }
                        .onChange(of: proxy.safeAreaInsets.bottom) { _, inset in bottomInset = inset }
                }
            )
            .ignoresSafeArea(.keyboard)
            .presentationDetents([.height(height + bottomInset)])
            .presentationDragIndicator(.visible)
    }
}

extension Text {
    /// Small all-caps label above an individual field. The letter-spacing is the
    /// point: at caption size, tracked uppercase reads as a deliberate label
    /// rather than as undersized body text.
    /// `color` is tertiary text unless the label carries meaning of its own (the
    /// round number in the accent, a badge in primary text).
    func sectionLabel(color: Color = Theme.textTertiary) -> some View {
        self
            .font(Theme.Typography.label)
            .textCase(.uppercase)
            .tracking(0.9)
            .foregroundColor(color)
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
