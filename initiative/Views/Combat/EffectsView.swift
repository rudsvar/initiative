import SwiftUI

/// Everything affecting one combatant, on one screen, applied by tapping.
///
/// Replaces a form that asked for a condition, a name, a duration and a
/// confirmation before anything happened — four decisions for "this creature is
/// stunned now". Here the conditions are all visible at once and **one tap
/// applies one**, using the duration that condition usually wants
/// (`StandardCondition.defaultDuration`). Tapping an already-applied one opens it
/// for configuring, because by then you've said which condition you mean and the
/// only remaining question is the duration.
///
/// The grid is the whole point: at sixteen conditions, showing them is cheaper
/// than making someone pick from a menu, and it doubles as the display of what's
/// currently active.
struct EffectsView: View {
    let session: CombatSession
    let combatantID: UUID
    @Binding var isPresented: Bool

    @State private var editing: Effect?
    @State private var creatingCustom = false

    private var combatant: Combatant? {
        session.combatants.first { $0.id == combatantID }
    }

    /// Computed synchronously so `FlowLayout` has a correct width on the first
    /// layout pass — `List` self-sizes a row once, so a width that only arrives a
    /// frame later leaves the row too short and clips the wrapped rows. Same
    /// reasoning as `CombatantRow`.
    private var contentWidth: CGFloat {
        UIScreen.main.bounds.width - (2 * Theme.Spacing.lg + 2 * Theme.Spacing.md)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()
                List {
                    if let combatant, !combatant.visibleEffects.isEmpty {
                        activeSection(combatant)
                    }
                    conditionsSection
                    cooldownsSection
                    customSection
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(combatant?.name ?? "Effects")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { isPresented = false }.fontWeight(.semibold)
                }
            }
            .sheet(item: $editing) { effect in
                EffectEditorView(session: session, combatantID: combatantID, existing: effect)
            }
            .sheet(isPresented: $creatingCustom) {
                EffectEditorView(session: session, combatantID: combatantID, existing: nil)
            }
        }
    }

    // MARK: - Active

    /// Listed as rows rather than only as lit-up chips, because a chip can show
    /// *that* something is active but not for how much longer, and the duration
    /// is the thing you actually check mid-combat.
    private func activeSection(_ combatant: Combatant) -> some View {
        Section {
            ForEach(combatant.visibleEffects) { effect in
                Button { editing = effect } label: {
                    HStack(spacing: Theme.Spacing.md) {
                        Image(systemName: symbol(for: effect))
                            .font(Theme.Typography.iconRow)
                            .foregroundColor(tint(for: effect))
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                            Text(effect.name)
                                .font(Theme.Typography.bodyEmphasis)
                                .foregroundColor(Theme.textPrimary)
                            Text(effect.durationType.description)
                                .font(Theme.Typography.caption)
                                .foregroundColor(Theme.textTertiary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer(minLength: 0)
                    }
                }
                .cardRowStyle()
                .cardRowLayout()
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        session.removeEffect(effect.id, from: combatantID)
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                }
            }
        } header: {
            Text("Active").sectionLabel()
        }
    }

    // MARK: - Pickers

    private var conditionsSection: some View {
        Section {
            FlowLayout {
                ForEach(ConditionLibrary.all) { condition in
                    let active = session.effect(named: condition.name, on: combatantID)
                    ChipButton(
                        symbolName: condition.symbolName,
                        label: condition.name,
                        tint: condition.color,
                        isActive: active != nil
                    ) {
                        if let active {
                            editing = active
                        } else {
                            session.addEffect(
                                Effect(name: condition.name, durationType: condition.defaultDuration),
                                to: combatantID
                            )
                        }
                    }
                }
            }
            .frame(width: contentWidth, alignment: .leading)
            .cardRowLayout()
        } header: {
            Text("Conditions").sectionLabel()
        }
    }

    private var cooldownsSection: some View {
        Section {
            FlowLayout {
                ForEach(StandardCooldown.all) { cooldown in
                    ChipButton(
                        symbolName: cooldown.durationType.awaitsRoll ? "hourglass" : "clock",
                        label: cooldown.label,
                        tint: Theme.textSecondary,
                        isActive: false
                    ) {
                        // Named after the ability, not the cooldown — the DM
                        // renames it in the editor, which is why this opens there
                        // rather than applying silently like a condition does.
                        editing = nil
                        let effect = Effect(
                            name: cooldown.effectName,
                            durationType: cooldown.durationType,
                            kind: .cooldown
                        )
                        session.addEffect(effect, to: combatantID)
                        editing = effect
                    }
                }
            }
            .frame(width: contentWidth, alignment: .leading)
            .cardRowLayout()
        } header: {
            Text("Cooldowns").sectionLabel()
        }
    }

    private var customSection: some View {
        Section {
            Button { creatingCustom = true } label: {
                Label("Custom effect…", systemImage: "square.and.pencil")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.accent)
            }
            .cardRowStyle()
            .cardRowLayout()
        }
    }

    // MARK: - Helpers

    private func symbol(for effect: Effect) -> String {
        if effect.kind == .cooldown {
            return effect.durationType.awaitsRoll ? "hourglass" : "clock"
        }
        return ConditionLibrary.matching(name: effect.name)?.symbolName ?? "sparkles"
    }

    private func tint(for effect: Effect) -> Color {
        effect.kind == .cooldown
            ? Theme.textTertiary
            : (ConditionLibrary.matching(name: effect.name)?.color ?? Theme.accent)
    }
}

/// A tappable chip. Active state is carried by fill plus a check, not by colour
/// alone — at chip size a "slightly more saturated" version of the same hue isn't
/// a state you can read at a glance across sixteen of them.
private struct ChipButton: View {
    let symbolName: String
    let label: String
    let tint: Color
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: isActive ? "checkmark" : symbolName)
                    .font(Theme.Typography.iconChip)
                Text(label)
                    .font(Theme.Typography.label)
            }
            .foregroundColor(isActive ? tint : Theme.textSecondary)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs + 2)
            .background(isActive ? tint.opacity(0.20) : Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                    .stroke(isActive ? tint.opacity(0.55) : Theme.border.opacity(0.5),
                            lineWidth: Theme.hairline)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let session = CombatSession()
    session.addCombatant(name: "Bog Hulk", initiative: 18, maxHP: 84)
    let id = session.combatants[0].id
    session.addEffect(Effect(name: "Stunned", durationType: .untilRollSucceeds(at: .endOfTurn, hint: nil)), to: id)

    return EffectsView(session: session, combatantID: id, isPresented: .constant(true))
}
