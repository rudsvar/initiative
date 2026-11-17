#if DEBUG
import SwiftUI

/// Debug-only list of the test-only combats, styled like Load Session. Opening one
/// replaces the current session with that scenario and goes to the combat screen,
/// whose back button returns here. Not in Release builds.
struct DebugScenariosView: View {
    let session: CombatSession
    @Binding var path: NavigationPath

    var body: some View {
        List {
            ForEach(TestCombats.scenarios.keys.sorted(), id: \.self) { name in
                let combatants = TestCombats.scenarios[name]!().combatants
                Button {
                    session.load(TestCombats.scenarios[name]!().makeRecord())
                    path.append(Route.scenarioCombat)
                } label: {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text(Self.title(for: name))
                            .font(Theme.Typography.rowTitle)
                            .foregroundColor(Theme.textPrimary)
                        Text(combatants.map(\.name).joined(separator: ", "))
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.textTertiary)
                    }
                }
                .buttonStyle(CardRowButtonStyle())
                .cardRowLayout()
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .themedScreen()
        .navigationTitle("Test Scenarios")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// "deadCreatureIsSkipped" reads as "Dead creature is skipped". A run of
    /// capitals is one word ("ACChanges" is "AC changes"), and HP and AC stay
    /// in capitals.
    static func title(for name: String) -> String {
        let letters = Array(name)
        var words: [String] = []
        for (i, letter) in letters.enumerated() {
            let previous = i > 0 ? letters[i - 1] : nil
            let next = i + 1 < letters.count ? letters[i + 1] : nil
            let startsWord = letter.isUppercase
                && (previous?.isLowercase == true || (previous?.isUppercase == true && next?.isLowercase == true))
            if words.isEmpty || startsWord {
                words.append(String(letter))
            } else {
                words[words.count - 1].append(letter)
            }
        }
        let acronyms: Set = ["hp", "ac"]
        let shaped = words.map { acronyms.contains($0.lowercased()) ? $0.uppercased() : $0.lowercased() }
        let sentence = shaped.joined(separator: " ")
        return sentence.prefix(1).uppercased() + sentence.dropFirst()
    }
}
#endif
