import SwiftUI

/// Shared "old paper" color palette used across all views.
enum Theme {
    static let background = Color(red: 0.96, green: 0.94, blue: 0.93)
    static let accent = Color(red: 0.78, green: 0.14, blue: 0.11)
    static let textPrimary = Color(red: 0.17, green: 0.15, blue: 0.13)
    static let textSecondary = Color(red: 0.43, green: 0.35, blue: 0.32)
    static let textTertiary = Color(red: 0.60, green: 0.50, blue: 0.45)
    static let divider = Color(red: 0.83, green: 0.76, blue: 0.72)
}

/// A small circular letter badge — e.g. a red "R" for reaction status — built
/// entirely from SwiftUI shapes/text, no image asset needed. Filled + bold when
/// "on" (e.g. reaction available), outlined + muted when "off" (used up).
struct LetterBadge: View {
    let letter: String
    let isOn: Bool
    var size: CGFloat = 16

    var body: some View {
        Text(letter)
            .font(.system(size: size * 0.6, weight: .bold))
            .foregroundColor(isOn ? .white : Theme.textTertiary)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(isOn ? Theme.accent : Color.clear)
                    .overlay(Circle().stroke(isOn ? Color.clear : Theme.divider, lineWidth: 1.5))
            )
    }
}
