import SwiftUI

/// The optional challenge rating field, used by the creature form and the clone
/// sheet so both offer the same choices. A menu of the fixed ratings, so nothing
/// is mistyped, with "None" for a creature that has no rating.
struct ChallengeRatingPicker: View {
    @Binding var selection: String?

    var body: some View {
        Picker(selection: $selection) {
            Text("None").tag(String?.none)
            ForEach(ChallengeRating.all, id: \.self) { rating in
                Text(Self.label(rating)).tag(String?.some(rating))
            }
        } label: {
            Text("Challenge Rating").foregroundColor(Theme.textPrimary)
        }
        .pickerStyle(.menu)
    }

    /// "1/4 · 50 XP"
    static func label(_ rating: String) -> String {
        guard let xp = ChallengeRating.xp(for: rating) else { return rating }
        return "\(rating) · \(xp) XP"
    }
}
