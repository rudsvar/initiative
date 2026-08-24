import SwiftUI

struct CombatantDetailView: View {
    let session: CombatSession
    let combatantId: UUID
    @Environment(\.dismiss) var dismiss
    @State private var showAddEffect = false
    @State private var showEnableHP = false
    @State private var newMaxHPText = ""
    @State private var damageHealAmount = ""
    @State private var maxIncreaseAmount = ""

    var combatant: Combatant? {
        session.combatants.first { $0.id == combatantId }
    }

    private var currentHPBinding: Binding<String> {
        Binding(
            get: { combatant?.currentHP.map(String.init) ?? "" },
            set: { newValue in
                guard let index = session.combatants.firstIndex(where: { $0.id == combatantId }),
                      let maxHP = session.combatants[index].maxHP,
                      let value = Int(newValue) else { return }
                session.combatants[index].currentHP = min(maxHP, max(0, value))
            }
        )
    }

    private var maxHPBinding: Binding<String> {
        Binding(
            get: { combatant?.maxHP.map(String.init) ?? "" },
            set: { newValue in
                guard let index = session.combatants.firstIndex(where: { $0.id == combatantId }),
                      let value = Int(newValue), value > 0 else { return }
                session.combatants[index].maxHP = value
                if let current = session.combatants[index].currentHP, current > value {
                    session.combatants[index].currentHP = value
                }
            }
        )
    }

    private var nameBinding: Binding<String> {
        Binding(
            get: { combatant?.name ?? "" },
            set: { newValue in
                guard let index = session.combatants.firstIndex(where: { $0.id == combatantId }) else { return }
                session.combatants[index].name = newValue
            }
        )
    }

    private var initiativeBinding: Binding<String> {
        Binding(
            get: { combatant.map { String($0.initiative) } ?? "" },
            set: { newValue in
                guard let index = session.combatants.firstIndex(where: { $0.id == combatantId }) else { return }
                guard let value = Int(newValue) else { return }
                session.combatants[index].initiative = value
            }
        )
    }

    private var armorClassBinding: Binding<String> {
        Binding(
            get: { combatant?.armorClass.map(String.init) ?? "" },
            set: { newValue in
                guard let index = session.combatants.firstIndex(where: { $0.id == combatantId }) else { return }
                session.combatants[index].armorClass = Int(newValue)
            }
        )
    }

    var body: some View {
        ScrollView {
            if let combatant = combatant {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    identityCard(for: combatant)
                    healthCard(for: combatant)
                    reactionCard(for: combatant)
                    effectsCard(for: combatant)
                }
                .padding(Theme.Spacing.lg)
            }
        }
        .themedScreen()
        .navigationTitle("Combatant")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddEffect) {
            if let combatant = combatant {
                AddEffectView(
                    session: session,
                    combatant: combatant,
                    isPresented: $showAddEffect
                )
            }
        }
        .alert("Track HP", isPresented: $showEnableHP) {
            TextField(text: $newMaxHPText) {
                Text("Max HP").foregroundColor(Theme.placeholderText)
            }
            .keyboardType(.numberPad)
            Button("Start Tracking") {
                if let value = Int(newMaxHPText), value > 0 {
                    session.enableHPTracking(for: combatantId, maxHP: value)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Cards

    /// Name on its own line (it's the long field), with initiative and armor
    /// class side by side underneath — both are short numbers, and stacking them
    /// in separate full-width rows wasted most of the screen's width.
    private func identityCard(for combatant: Combatant) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Name").sectionLabel()
                TextField(text: nameBinding) {
                    Text("Name").foregroundColor(Theme.placeholderText)
                }
                .font(Theme.Typography.title)
                .foregroundColor(Theme.textPrimary)
                .fieldStyle()
            }

            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Initiative").sectionLabel()
                    TextField(text: initiativeBinding) {
                        Text("—").foregroundColor(Theme.placeholderText)
                    }
                    .keyboardType(.numberPad)
                    .font(Theme.Typography.statLarge)
                    .foregroundColor(Theme.accent)
                    .multilineTextAlignment(.center)
                    .fieldStyle(width: 84)
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Armor Class").sectionLabel()
                    TextField(text: armorClassBinding) {
                        Text("—").foregroundColor(Theme.placeholderText)
                    }
                    .keyboardType(.numberPad)
                    .font(Theme.Typography.statLarge)
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .fieldStyle(width: 84)
                }

                Spacer(minLength: 0)

                if combatant.isDead {
                    DeadBadge()
                        .padding(.top, Theme.Spacing.lg)
                }
            }
        }
        .sectionCard()
    }

    /// One width for every box in the Health card. They sit in two stacked rows
    /// and read as a grid, so Amount being narrower than Current/Max made the
    /// columns visibly fail to line up.
    private static let hpFieldWidth: CGFloat = 74

    private func healthCard(for combatant: Combatant) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Health").cardHeading()

            if combatant.maxHP != nil {
                // Current above Max, each with its own inline Amount field +
                // action button(s) right next to it — replaces a shared single
                // Amount field feeding three buttons, which put Increase Max HP
                // oddly far from the Max HP box it actually affects.
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    HStack(alignment: .bottom, spacing: Theme.Spacing.sm) {
                        labelledField(
                            "Current",
                            text: currentHPBinding,
                            placeholder: "HP",
                            color: combatant.isDead ? Theme.textTertiary : Theme.accent,
                            width: Self.hpFieldWidth
                        )
                        labelledField(
                            "Amount",
                            text: $damageHealAmount,
                            placeholder: "–",
                            color: Theme.textPrimary,
                            width: Self.hpFieldWidth
                        )

                        Spacer(minLength: 0)

                        hpButton("minus", tint: Theme.statusBad, label: "Damage") {
                            applyDamage(to: combatant)
                        }
                        .disabled(Int(damageHealAmount) == nil)

                        hpButton("plus", tint: Theme.statusGood, label: "Heal") {
                            applyHealing(to: combatant)
                        }
                        .disabled(Int(damageHealAmount) == nil)
                    }

                    HStack(alignment: .bottom, spacing: Theme.Spacing.sm) {
                        labelledField(
                            "Max",
                            text: maxHPBinding,
                            placeholder: "Max",
                            color: Theme.textPrimary,
                            width: Self.hpFieldWidth
                        )
                        labelledField(
                            "Amount",
                            text: $maxIncreaseAmount,
                            placeholder: "–",
                            color: Theme.textPrimary,
                            width: Self.hpFieldWidth
                        )

                        Spacer(minLength: 0)

                        hpButton("arrow.up", tint: Theme.statusInfo, label: "Increase Max HP") {
                            increaseMaxHP(for: combatant)
                        }
                        .disabled(Int(maxIncreaseAmount) == nil)
                    }
                }
            } else {
                Button(action: { newMaxHPText = ""; showEnableHP = true }) {
                    Label("Track HP", systemImage: "heart.fill")
                        .font(Theme.Typography.bodyEmphasis)
                        .foregroundColor(Theme.accent)
                }
            }
        }
        .sectionCard()
    }

    private func reactionCard(for combatant: Combatant) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Reaction").cardHeading()
            ReactionToggleView(
                isUsed: combatant.reactionUsed,
                onToggle: { toggleReaction(for: combatant) }
            )
        }
        .sectionCard()
    }

    private func effectsCard(for combatant: Combatant) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("Active Effects").cardHeading()
                Spacer()
                Button(action: { showAddEffect = true }) {
                    Label("Add", systemImage: "plus")
                        .font(Theme.Typography.label)
                        .foregroundColor(Theme.accent)
                }
            }

            if combatant.visibleEffects.isEmpty {
                Text("None active.")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.textTertiary)
                    .padding(.vertical, Theme.Spacing.xs)
            } else {
                VStack(spacing: Theme.Spacing.sm) {
                    ForEach(combatant.visibleEffects) { effect in
                        EffectRowView(
                            effect: effect,
                            onRemove: { removeEffect(effect, from: combatant) }
                        )
                    }
                }
            }
        }
        .sectionCard()
    }

    // MARK: - Small building blocks

    private func labelledField(
        _ label: String,
        text: Binding<String>,
        placeholder: String,
        color: Color,
        width: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(label).sectionLabel()
            TextField(text: text) {
                Text(placeholder).foregroundColor(Theme.placeholderText)
            }
            .keyboardType(.numberPad)
            .font(Theme.Typography.statLarge)
            .foregroundColor(color)
            .multilineTextAlignment(.center)
            .fieldStyle(width: width)
        }
    }

    /// A tinted circular action button. The glyph is a bare `minus`/`plus`/`arrow`
    /// on a tinted disc rather than a `.circle.fill` symbol so the disc size is
    /// ours to control and all three buttons match regardless of glyph.
    private func hpButton(
        _ systemImage: String,
        tint: Color,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(Theme.Typography.iconAction)
                .foregroundColor(tint)
                .frame(width: 38, height: 38)
                .background(tint.opacity(0.16))
                .clipShape(Circle())
                .overlay(Circle().stroke(tint.opacity(0.35), lineWidth: Theme.hairline))
        }
        .accessibilityLabel(label)
    }

    // MARK: - Actions

    private func applyDamage(to combatant: Combatant) {
        guard let amount = Int(damageHealAmount) else { return }
        session.applyDamage(to: combatant.id, amount: amount)
        damageHealAmount = ""
    }

    private func applyHealing(to combatant: Combatant) {
        guard let amount = Int(damageHealAmount) else { return }
        session.applyHealing(to: combatant.id, amount: amount)
        damageHealAmount = ""
    }

    private func increaseMaxHP(for combatant: Combatant) {
        guard let amount = Int(maxIncreaseAmount) else { return }
        session.increaseMaxHP(for: combatant.id, amount: amount)
        maxIncreaseAmount = ""
    }

    private func toggleReaction(for combatant: Combatant) {
        session.toggleReaction(for: combatant.id)
    }

    private func removeEffect(_ effect: Effect, from combatant: Combatant) {
        if let index = session.combatants.firstIndex(where: { $0.id == combatant.id }) {
            session.combatants[index].effects.removeAll { $0.id == effect.id }
        }
    }
}

struct DeadBadge: View {
    var body: some View {
        HStack(spacing: Theme.Spacing.xs + 2) {
            Image(systemName: "skull.fill")
            Text("Dead")
                .font(Theme.Typography.label)
                .textCase(.uppercase)
                .tracking(0.9)
        }
        .font(Theme.Typography.iconInline)
        .foregroundColor(Theme.textPrimary)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs + 2)
        .background(Theme.background)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Theme.border, lineWidth: Theme.hairline))
    }
}

struct ReactionToggleView: View {
    let isUsed: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: "arrow.uturn.left")
                    .font(Theme.Typography.iconRowProminent)
                    .foregroundColor(isUsed ? Theme.textTertiary : Theme.accent)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text(isUsed ? "Reaction Used" : "Reaction Available")
                        .font(Theme.Typography.bodyEmphasis)
                        .foregroundColor(Theme.textPrimary)

                    Text(isUsed ? "Tap to mark available" : "Tap to mark used")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.textTertiary)
                }

                Spacer()
            }
            .padding(Theme.Spacing.md)
            .background(isUsed ? Theme.surfaceRaised : Theme.accentSoft)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                    .stroke(isUsed ? Theme.border.opacity(0.5) : Theme.accent.opacity(0.4), lineWidth: Theme.hairline)
            )
        }
    }
}

struct EffectRowView: View {
    let effect: Effect
    let onRemove: () -> Void

    private var condition: StandardCondition? {
        ConditionLibrary.matching(name: effect.name)
    }

    private var tint: Color { condition?.color ?? Theme.accent }

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: condition?.symbolName ?? "sparkles")
                .font(Theme.Typography.iconRow)
                .foregroundColor(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.14))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(effect.name)
                    .font(Theme.Typography.bodyEmphasis)
                    .foregroundColor(Theme.textPrimary)

                Text(effect.durationType.description)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.textTertiary)
            }

            Spacer()

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(Theme.Typography.iconControl)
                    .foregroundColor(Theme.textTertiary)
                    .padding(Theme.Spacing.sm)
            }
            .accessibilityLabel("Remove \(effect.name)")
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Theme.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        CombatantDetailView(
            session: {
                let session = CombatSession()
                session.addCombatant(name: "Goblin", initiative: 15)
                return session
            }(),
            combatantId: UUID()
        )
    }
}
