import SwiftUI

/// The rolls owed at a turn boundary, asked once and together.
///
/// **Deliberately not dismissible.** These are precisely the things that get
/// forgotten mid-combat, and a prompt you can wave away is one you will wave
/// away — so there's no Cancel, and the turn doesn't advance until every line has
/// an answer. The cost of being insistent is only paid when something is
/// genuinely owed, which is a minority of turns.
struct TurnPromptView: View {
    let prompts: [TurnPrompt]
    /// Called with every prompt's outcome once all of them have one.
    let onComplete: ([TurnPrompt: Bool]) -> Void

    @State private var answers: [TurnPrompt: Bool] = [:]

    private var allAnswered: Bool { answers.count == prompts.count }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Theme.Spacing.md) {
                        ForEach(prompts) { prompt in
                            promptCard(prompt)
                        }
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
            .navigationTitle(prompts.count == 1 ? "One roll owed" : "\(prompts.count) rolls owed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Continue") { onComplete(answers) }
                        .fontWeight(.semibold)
                        .disabled(!allAnswered)
                }
            }
            .interactiveDismissDisabled()
        }
    }

    private func promptCard(_ prompt: TurnPrompt) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(prompt.combatantName).sectionLabel()
                Text(prompt.title).cardHeading()

                if let hint = prompt.hint {
                    Text(hint)
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.textSecondary)
                }

                if let saves = prompt.deathSaves {
                    Text("\(saves.successes) made · \(saves.failures) failed")
                        .font(Theme.Typography.stat)
                        .foregroundColor(Theme.textTertiary)
                }
            }

            HStack(spacing: Theme.Spacing.sm) {
                answerButton(prompt.successLabel, tint: Theme.statusGood, isChosen: answers[prompt] == true) {
                    answers[prompt] = true
                }
                answerButton(prompt.failureLabel, tint: Theme.statusBad, isChosen: answers[prompt] == false) {
                    answers[prompt] = false
                }
            }
        }
        .sectionCard()
    }

    /// Answers stay visible and re-tappable rather than the card disappearing on
    /// choice: a mistap on the first of three prompts shouldn't be unfixable
    /// before you've even pressed Continue.
    private func answerButton(_ label: String, tint: Color, isChosen: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(Theme.Typography.bodyEmphasis)
                .foregroundColor(isChosen ? Theme.accentForeground : tint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.sm)
                .background(isChosen ? tint : tint.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                        .stroke(tint.opacity(isChosen ? 0 : 0.4), lineWidth: Theme.hairline)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TurnPromptView(
        prompts: [
            TurnPrompt(
                id: UUID(), combatantID: UUID(), combatantName: "Bog Hulk",
                subject: .effect(id: UUID()), title: "Roll to recharge Breath Weapon",
                hint: "5–6 on a d6", deathSaves: nil
            ),
            TurnPrompt(
                id: UUID(), combatantID: UUID(), combatantName: "Wren",
                subject: .deathSave, title: "Death save",
                hint: nil, deathSaves: DeathSaves(successes: 1, failures: 1)
            ),
        ],
        onComplete: { _ in }
    )
}
