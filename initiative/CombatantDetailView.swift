import SwiftUI

struct CombatantDetailView: View {
    let session: CombatSession
    let combatantId: UUID
    @Environment(\.dismiss) var dismiss
    @State private var showAddEffect = false
    @State private var showEnableHP = false
    @State private var newMaxHPText = ""
    @State private var hpAdjustAmount = ""

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

    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()

            if let combatant = combatant {
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Name")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Theme.textTertiary)
                                TextField("Name", text: nameBinding)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Theme.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Theme.background)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Theme.divider, lineWidth: 1)
                                    )

                                Text("Initiative")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Theme.textTertiary)
                                TextField("Initiative", text: initiativeBinding)
                                    .keyboardType(.numberPad)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Theme.accent)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .frame(width: 88)
                                    .background(Theme.background)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Theme.divider, lineWidth: 1)
                                    )

                                if combatant.isDead {
                                    DeadBadge()
                                }
                            }
                            .padding(16)
                            .background(Theme.divider.opacity(0.2))
                            .cornerRadius(8)

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Health")
                                    .font(.headline)
                                    .foregroundColor(Theme.textPrimary)

                                if combatant.maxHP != nil {
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Current")
                                                .font(.caption)
                                                .foregroundColor(Theme.textTertiary)
                                            TextField("HP", text: currentHPBinding)
                                                .keyboardType(.numberPad)
                                                .font(.title3)
                                                .fontWeight(.bold)
                                                .foregroundColor(combatant.isDead ? Theme.textTertiary : Theme.accent)
                                                .multilineTextAlignment(.center)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .frame(width: 72)
                                                .background(Theme.background)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Theme.divider, lineWidth: 1)
                                                )
                                        }

                                        Text("/")
                                            .font(.title3)
                                            .foregroundColor(Theme.textTertiary)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Max")
                                                .font(.caption)
                                                .foregroundColor(Theme.textTertiary)
                                            TextField("Max HP", text: maxHPBinding)
                                                .keyboardType(.numberPad)
                                                .font(.title3)
                                                .fontWeight(.bold)
                                                .foregroundColor(Theme.textPrimary)
                                                .multilineTextAlignment(.center)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .frame(width: 72)
                                                .background(Theme.background)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Theme.divider, lineWidth: 1)
                                                )
                                        }

                                        Spacer()
                                    }

                                    VStack(alignment: .leading, spacing: 8) {
                                        TextField("Amount", text: $hpAdjustAmount)
                                            .keyboardType(.numberPad)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .frame(maxWidth: .infinity)
                                            .background(Theme.background)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Theme.divider, lineWidth: 1)
                                            )

                                        HStack(spacing: 12) {
                                            Button(action: { applyDamage(to: combatant) }) {
                                                Label("Damage", systemImage: "minus.circle.fill")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .frame(maxWidth: .infinity)
                                            }
                                            .foregroundColor(.red)
                                            .disabled(Int(hpAdjustAmount) == nil)

                                            Button(action: { applyHealing(to: combatant) }) {
                                                Label("Heal", systemImage: "plus.circle.fill")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .frame(maxWidth: .infinity)
                                            }
                                            .foregroundColor(.green)
                                            .disabled(Int(hpAdjustAmount) == nil)
                                        }

                                        Button(action: { increaseMaxHP(for: combatant) }) {
                                            Label("Increase Max HP", systemImage: "arrow.up.heart.fill")
                                                .font(.system(size: 14, weight: .semibold))
                                                .frame(maxWidth: .infinity)
                                        }
                                        .foregroundColor(.blue)
                                        .disabled(Int(hpAdjustAmount) == nil)
                                    }
                                    .padding(.top, 4)
                                } else {
                                    Button(action: { newMaxHPText = ""; showEnableHP = true }) {
                                        Label("Track HP", systemImage: "heart.fill")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Theme.accent)
                                    }
                                }
                            }
                            .padding(16)
                            .background(Theme.divider.opacity(0.2))
                            .cornerRadius(8)

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Reaction")
                                    .font(.headline)
                                    .foregroundColor(Theme.textPrimary)

                                ReactionToggleView(
                                    isUsed: combatant.reactionUsed,
                                    onToggle: { toggleReaction(for: combatant) }
                                )
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Active Effects")
                                        .font(.headline)
                                        .foregroundColor(Theme.textPrimary)

                                    Spacer()

                                    Button(action: { showAddEffect = true }) {
                                        Label("Add", systemImage: "plus.circle.fill")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Theme.accent)
                                    }
                                }

                                if combatant.effects.isEmpty {
                                    VStack(spacing: 8) {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 32))
                                            .foregroundColor(Theme.divider)
                                        Text("No active effects")
                                            .font(.subheadline)
                                            .foregroundColor(Theme.textTertiary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(20)
                                } else {
                                    VStack(spacing: 8) {
                                        ForEach(combatant.effects) { effect in
                                            EffectRowView(
                                                effect: effect,
                                                onRemove: { removeEffect(effect, from: combatant) }
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
        }
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
            TextField("Max HP", text: $newMaxHPText)
                .keyboardType(.numberPad)
            Button("Start Tracking") {
                if let value = Int(newMaxHPText), value > 0 {
                    session.enableHPTracking(for: combatantId, maxHP: value)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func applyDamage(to combatant: Combatant) {
        guard let amount = Int(hpAdjustAmount) else { return }
        session.applyDamage(to: combatant.id, amount: amount)
        hpAdjustAmount = ""
    }

    private func applyHealing(to combatant: Combatant) {
        guard let amount = Int(hpAdjustAmount) else { return }
        session.applyHealing(to: combatant.id, amount: amount)
        hpAdjustAmount = ""
    }

    private func increaseMaxHP(for combatant: Combatant) {
        guard let amount = Int(hpAdjustAmount) else { return }
        session.increaseMaxHP(for: combatant.id, amount: amount)
        hpAdjustAmount = ""
    }

    private func toggleReaction(for combatant: Combatant) {
        if let index = session.combatants.firstIndex(where: { $0.id == combatant.id }) {
            session.combatants[index].reactionUsed.toggle()
        }
    }

    private func removeEffect(_ effect: Effect, from combatant: Combatant) {
        if let pIndex = session.combatants.firstIndex(where: { $0.id == combatant.id }) {
            session.combatants[pIndex].effects.removeAll { $0.id == effect.id }
        }
    }
}

struct DeadBadge: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "skull.fill")
            Text("Dead")
                .fontWeight(.bold)
        }
        .font(.subheadline)
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.7))
        .cornerRadius(6)
    }
}

struct ReactionToggleView: View {
    let isUsed: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                LetterBadge(letter: "R", isOn: !isUsed, size: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(isUsed ? "Reaction Used" : "Reaction Available")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.textPrimary)

                    Text(isUsed ? "Mark as available" : "Mark as used")
                        .font(.caption)
                        .foregroundColor(Theme.textTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.divider)
            }
            .padding(12)
            .background(isUsed ? Theme.divider.opacity(0.2) : Theme.accent.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

struct EffectRowView: View {
    let effect: Effect
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(effect.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.textPrimary)

                Text(effect.durationType.description)
                    .font(.caption)
                    .foregroundColor(Theme.textTertiary)
            }

            Spacer()

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.divider)
            }
        }
        .padding(12)
        .background(Theme.divider.opacity(0.2))
        .cornerRadius(8)
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
