import SwiftUI

/// The rolls owed at a turn boundary, asked once and together.
///
/// **Dismissible at any time — swiping away just leaves the turn where it
/// was.** Nothing here is applied until every prompt has an answer (see
/// `onComplete`), so backing out mid-prompt can't half-advance anything;
/// worst case you reopen the same prompts on the next attempt to advance.
/// Answering still needs no confirmation of its own: this is the middle of
/// combat, and a mis-tap is rare enough that trading "tap once, fix it by
/// hand if wrong" for "tap, then tap Continue" on every single roll is the
/// wrong side of that bet. Tapping an answer resolves it immediately; the
/// sheet dismisses itself the instant the last one is answered.
///
/// A compact card rather than a full navigation screen — see `compactSheet()`.
struct TurnPromptView: View {
    let prompts: [TurnPrompt]
    /// Called with every prompt's outcome once all of them have one, and the amount
    /// typed for each damage prompt.
    let onComplete: ([TurnPrompt: RollOutcome], [TurnPrompt: Int]) -> Void

    @State private var answers: [TurnPrompt: RollOutcome] = [:]
    @State private var damage: [TurnPrompt: Int] = [:]
    @State private var damageText = ""

    /// One at a time rather than every prompt stacked in the sheet at once —
    /// with several owed together (a few death saves plus a recharge, say)
    /// the stacked version had no `ScrollView`, so `selfSizingSheet()` would
    /// measure a height taller than the screen and there was no way to reach
    /// what didn't fit: not scrollable, and dragging the sheet couldn't
    /// expand it past its own fixed detent either. Showing just the next
    /// unanswered prompt keeps the sheet's height bounded no matter how many
    /// are owed, and answering one during combat at a time is the more
    /// natural shape for it anyway.
    private var current: TurnPrompt? {
        prompts.first { answers[$0] == nil }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text(prompts.count == 1 ? "Roll owed" : "Roll \(answers.count + 1) of \(prompts.count)")
                .font(Theme.Typography.label)
                .foregroundColor(Theme.textTertiary)

            if let current {
                promptCard(current)
            }
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .compactSheet()
        .onChange(of: answers) { _, newValue in
            guard newValue.count == prompts.count else { return }
            onComplete(newValue, damage)
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

            if case .damage = prompt.subject {
                // The DM rolls; the app takes the number.
                TextField(text: $damageText) {
                    Text("Damage rolled").foregroundColor(Theme.placeholderText)
                }
                .keyboardType(.numberPad)
                .fieldStyle()
                HStack(spacing: Theme.Spacing.sm) {
                    answerButton("Apply damage", tint: Theme.statusBad) {
                        if let amount = Int(damageText), amount > 0 { damage[prompt] = amount }
                        damageText = ""
                        answers[prompt] = .success
                    }
                    .disabled((Int(damageText) ?? 0) <= 0)
                    answerButton("No damage", tint: Theme.textSecondary) {
                        damageText = ""
                        answers[prompt] = .failure
                    }
                }
            } else if case .deathSave = prompt.subject {
                // A death save can be a natural 20 or a natural 1, as well as a plain result.
                HStack(spacing: Theme.Spacing.sm) {
                    answerButton("Success", tint: Theme.statusGood) { answers[prompt] = .success }
                    answerButton("Failure", tint: Theme.statusBad) { answers[prompt] = .failure }
                }
                HStack(spacing: Theme.Spacing.sm) {
                    answerButton("Natural 20", tint: Theme.statusGood) { answers[prompt] = .criticalSuccess }
                    answerButton("Natural 1", tint: Theme.statusBad) { answers[prompt] = .criticalFailure }
                }
            } else {
                HStack(spacing: Theme.Spacing.sm) {
                    answerButton(prompt.successLabel, tint: Theme.statusGood) {
                        answers[prompt] = .success
                    }
                    answerButton(prompt.failureLabel, tint: Theme.statusBad) {
                        answers[prompt] = .failure
                    }
                }
            }
        }
    }

    /// No "chosen" visual state to hold onto: the tap resolves the prompt and,
    /// once every prompt has one, the whole sheet is gone before there'd be
    /// anything left to look at.
    private func answerButton(_ label: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(Theme.Typography.bodyEmphasis)
                .foregroundColor(tint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.sm)
                .background(tint.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                        .stroke(tint.opacity(0.4), lineWidth: Theme.hairline)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
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
            onComplete: { _, _ in }
        )
    }
}
