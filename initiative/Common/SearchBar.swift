import SwiftUI

/// A themed search field pinned below a list.
///
/// Bottom-anchored rather than the system `.searchable` bar under the navigation
/// title, for two reasons: it's where the thumb already is on a phone held
/// one-handed at a table, and the app already puts its primary controls in a bar
/// at the bottom of the combat screen — so this reads as the same shape rather
/// than as a second, unrelated convention. Its chrome deliberately matches that
/// bar: the page color, a hairline along the top edge, nothing else.
///
/// Applied through `View.bottomSearchBar(...)` so both list screens get an
/// identical one from a single definition.
struct SearchBar: View {
    @Binding var text: String
    let prompt: String

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(Theme.Typography.iconRow)
                .foregroundColor(Theme.textTertiary)

            TextField(text: $text) {
                Text(prompt).foregroundColor(Theme.placeholderText)
            }
            .font(Theme.Typography.body)
            .foregroundColor(Theme.textPrimary)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .submitLabel(.search)
            .focused($isFocused)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(Theme.Typography.iconRow)
                        .foregroundColor(Theme.textTertiary)
                }
                .accessibilityLabel("Clear Search")
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Theme.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .stroke(isFocused ? Theme.accent.opacity(0.5) : Theme.border.opacity(0.6),
                        lineWidth: Theme.hairline)
        )
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Theme.background)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.border.opacity(0.5))
                .frame(height: Theme.hairline)
        }
    }
}

extension View {
    /// Pins a `SearchBar` below this view. `isVisible` is for the case where
    /// there's nothing to search yet — an empty library shows its
    /// `ContentUnavailableView` without a search field under it offering to
    /// filter nothing.
    func bottomSearchBar(text: Binding<String>, prompt: String, isVisible: Bool = true) -> some View {
        VStack(spacing: 0) {
            self
            if isVisible {
                SearchBar(text: text, prompt: prompt)
            }
        }
    }
}

#Preview {
    VStack {
        Spacer()
    }
    .bottomSearchBar(text: .constant(""), prompt: "Search creatures")
    .themedScreen()
}
