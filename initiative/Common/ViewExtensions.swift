import SwiftUI

extension View {
    func borderTop(_ color: Color, width: CGFloat = 1) -> some View {
        VStack(spacing: 0) {
            Divider()
                .foregroundColor(color)
                .frame(height: width)
            self
        }
    }

    func borderBottom(_ color: Color, width: CGFloat = 1) -> some View {
        VStack(spacing: 0) {
            self
            Divider()
                .foregroundColor(color)
                .frame(height: width)
        }
    }

    /// The bordered-card look used for every list row across the app (combatant
    /// rows, creature/encounter/session rows) — a visible border always, plus an
    /// accent-tinted fill and thicker border when `isHighlighted` (e.g. the
    /// current-turn combatant). One shared definition so every list stays visually
    /// consistent instead of each screen reimplementing its own row chrome.
    func cardRowStyle(isHighlighted: Bool = false) -> some View {
        self
            .padding(12)
            .background(isHighlighted ? Theme.accent.opacity(0.22) : Theme.background)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isHighlighted ? Theme.accent : Theme.divider, lineWidth: isHighlighted ? 2 : 1)
            )
            .cornerRadius(8)
    }
}
