import SwiftUI

struct CombatantDetailView: View {
    let session: CombatSession
    let combatantId: UUID
    @Environment(\.dismiss) var dismiss
    /// Raised when damage threatens something the combatant was holding. Damage
    /// isn't a turn boundary, so this is the one prompt that doesn't come from
    /// `pendingTurnPrompts`.
    @State private var concentrationCheck: TurnPrompt?
    @State private var showEnableHP = false
    @State private var newMaxHPText = ""
    /// Which effect the gear icon opened, or nil when adding a custom one.
    @State private var editingEffect: Effect?
    @State private var creatingCustom = false
    /// Which limited-use resource the cog opened, or nil when adding a new one.
    @State private var editingLimitedUse: LimitedUse?
    @State private var creatingLimitedUse = false

    var combatant: Combatant? {
        session.combatants.first { $0.id == combatantId }
    }

    /// A fixed two-column grid rather than a wrapping row of variable-width
    /// chips: it reads as a grid you scan up and down instead of a paragraph
    /// you scan left to right, and every chip gets the same, larger tap target
    /// regardless of how long its label is.
    private static let gridColumns = [GridItem(.flexible(), spacing: Theme.Spacing.sm), GridItem(.flexible())]

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

    /// Pushed from tapping a roster row — an inline-under-the-row disclosure
    /// was tried here and reverted (see CHANGELOG): SwiftUI's `List` animates
    /// a row's own height change internally regardless of whether the app
    /// code requests an animation, which made the row's own text visibly
    /// slide/fly as it resized. A pushed screen has no such row to resize.
    var body: some View {
        ScrollView {
            if let combatant = combatant {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    statsCard(for: combatant)
                    initiativeCard(for: combatant)
                    healthCard(for: combatant)
                    armorClassCard
                    actionsCard(for: combatant)
                    effectsCard(for: combatant)
                }
                .padding(Theme.Spacing.lg)
            }
        }
        .themedScreen()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Editable in place rather than a static title with a separate
            // Name field further down the screen — the same pattern as the
            // session name in ContentView's own top bar.
            ToolbarItem(placement: .principal) {
                SelectAllTextField(
                    text: nameBinding,
                    placeholder: "Name",
                    font: .preferredFont(forTextStyle: .headline).serif
                )
                .frame(width: 200, height: 24)
            }
        }
        .sheet(item: $concentrationCheck) { prompt in
            TurnPromptView(prompts: [prompt]) { answers in
                for (prompt, outcome) in answers {
                    session.resolvePrompt(prompt, outcome: outcome)
                }
                concentrationCheck = nil
            }
        }
        .sheet(item: $editingEffect) { effect in
            EffectEditorView(session: session, combatantID: combatantId, existing: effect)
        }
        .sheet(isPresented: $creatingCustom) {
            EffectEditorView(session: session, combatantID: combatantId, existing: nil)
        }
        .sheet(item: $editingLimitedUse) { use in
            LimitedUseEditorView(session: session, combatantID: combatantId, existing: use)
        }
        .sheet(isPresented: $creatingLimitedUse) {
            LimitedUseEditorView(session: session, combatantID: combatantId, existing: nil)
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

    /// The creature's stats: the facts from its stat block, when the app has one.
    private func statsCard(for combatant: Combatant) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Stats").cardHeading()
            if let block = SRDCatalog.bundled.first(where: { $0.name == combatant.name }) {
                StatFacts(block: block)
            } else {
                Text("No stat block in the app for this name.")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sectionCard()
    }

    /// Initiative on its own card, with a dead badge when the combatant is dead.
    private func initiativeCard(for combatant: Combatant) -> some View {
        HStack(alignment: .center, spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Initiative").cardHeading()
                TextField(text: initiativeBinding) {
                    Text("—").foregroundColor(Theme.placeholderText)
                }
                .keyboardType(.numberPad)
                .font(Theme.Typography.statLarge)
                .foregroundColor(Theme.accent)
                .fieldStyle(width: 68)
            }
            Spacer(minLength: 0)
            if combatant.isDead {
                DeadBadge()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sectionCard()
    }

    private var armorClassCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Armor Class").cardHeading()
            ArmorClassControlRow(session: session, combatantId: combatantId)
        }
        .sectionCard()
    }

    private func healthCard(for combatant: Combatant) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Health").cardHeading()

            if combatant.maxHP != nil {
                HealthControlRow(
                    session: session,
                    combatantId: combatantId,
                    onDamageApplied: { concentrationCheck = $0 }
                )
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

    /// Reaction, concentration, and any Legendary-Action-style counters — the
    /// things checked every single turn, none of which are "wrong with" the
    /// combatant the way a condition is. Above the Effects card rather than
    /// inside it, so the two things glanced at most often never scroll away
    /// under a long condition list.
    private func actionsCard(for combatant: Combatant) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            LazyVGrid(columns: Self.gridColumns, spacing: Theme.Spacing.sm) {
                EffectChip(
                    symbolName: "arrow.uturn.left",
                    label: "Reaction",
                    tint: Theme.textTertiary,
                    isActive: combatant.reactionUsed,
                    onTap: { toggleReaction(for: combatant) },
                    onConfigure: nil
                )
                EffectChip(
                    symbolName: "wand.and.rays",
                    label: "Concentrating",
                    tint: Theme.statusInfo,
                    isActive: combatant.isConcentrating,
                    onTap: { session.toggleConcentration(for: combatant.id) },
                    onConfigure: nil
                )
                ForEach(combatant.limitedUses) { use in
                    LimitedUseChip(
                        use: use,
                        onUse: { session.useLimitedUse(use.id, on: combatant.id) },
                        onConfigure: { editingLimitedUse = use }
                    )
                }
            }

            Button(action: { creatingLimitedUse = true }) {
                Label("Add Limited Use…", systemImage: "plus.circle")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.accent)
            }
        }
        .sectionCard()
    }

    /// One tap applies a condition with its usual duration and turns the chip
    /// colorful; a second tap on the same chip clears it. The gear that appears
    /// once a chip is active is the only way in — there's no separate "Manage"
    /// screen between tapping the combatant and changing what's wrong with them.
    ///
    /// A fixed two-column grid, not a wrapping row: every chip gets the same
    /// larger tap target regardless of label length, and the whole thing reads
    /// as a grid to scan rather than a paragraph of chips.
    private func effectsCard(for combatant: Combatant) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Effects").cardHeading()

            LazyVGrid(columns: Self.gridColumns, spacing: Theme.Spacing.sm) {
                ForEach(ConditionLibrary.all) { condition in
                    let active = session.effect(named: condition.name, on: combatant.id)
                    EffectChip(
                        symbolName: condition.symbolName,
                        label: condition.name,
                        tint: condition.color,
                        isActive: active != nil,
                        onTap: {
                            if let active {
                                session.removeEffect(active.id, from: combatant.id)
                            } else {
                                session.addEffect(
                                    Effect(name: condition.name, durationType: condition.defaultDuration),
                                    to: combatant.id
                                )
                            }
                        },
                        onConfigure: active.map { effect in { editingEffect = effect } }
                    )
                }
                // Only one cooldown template now (see `StandardCooldown`), so it
                // sits in the same grid as the conditions rather than under its
                // own header — a category of one doesn't need a label.
                ForEach(StandardCooldown.all) { cooldown in
                    EffectChip(
                        symbolName: cooldown.durationType.awaitsRoll ? "hourglass" : "clock",
                        label: cooldown.label,
                        tint: Theme.textSecondary,
                        isActive: false,
                        onTap: {
                            // Named after the ability, not the cooldown — the
                            // DM renames it in the editor that opens next.
                            let effect = Effect(
                                name: cooldown.effectName,
                                durationType: cooldown.durationType,
                                kind: .cooldown
                            )
                            session.addEffect(effect, to: combatant.id)
                            editingEffect = effect
                        },
                        onConfigure: nil
                    )
                }
            }

            // Cooldowns and custom effects are named per-use, so they can't be
            // shown as a fixed toggle grid the way conditions are — the row
            // itself carries the name, and tapping it opens the same editor.
            let otherEffects = combatant.visibleEffects.filter { ConditionLibrary.matching(name: $0.name) == nil }
            if !otherEffects.isEmpty {
                VStack(spacing: Theme.Spacing.sm) {
                    ForEach(otherEffects) { effect in
                        // `onTapGesture` rather than wrapping in a `Button`: the
                        // row already contains its own Remove button, and a
                        // button nested in a button loses its own tap target.
                        EffectRowView(effect: effect, onRemove: { removeEffect(effect, from: combatant) })
                            .contentShape(Rectangle())
                            .onTapGesture { editingEffect = effect }
                    }
                }
            }

            Button(action: { creatingCustom = true }) {
                Label("Custom effect…", systemImage: "square.and.pencil")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.accent)
            }
        }
        .sectionCard()
    }

    // MARK: - Actions

    private func toggleReaction(for combatant: Combatant) {
        session.toggleReaction(for: combatant.id)
    }

    private func removeEffect(_ effect: Effect, from combatant: Combatant) {
        session.removeEffect(effect.id, from: combatant.id)
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

/// A tappable chip that doubles as its own status readout. Active state is
/// carried by fill plus a checkmark, not by colour alone — at chip size a
/// "slightly more saturated" version of the same hue isn't a state you can read
/// at a glance across sixteen of them. The gear is a second, independent tap
/// target (not nested inside the main button) so configuring never fights with
/// toggling.
struct EffectChip: View {
    let symbolName: String
    let label: String
    let tint: Color
    let isActive: Bool
    let onTap: () -> Void
    var onConfigure: (() -> Void)?

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // `.frame(maxWidth: .infinity)` + `.contentShape(Rectangle())`
            // inside the button's own label, not just around the icon/text —
            // without them the tappable area was only as wide as the text
            // itself, so tapping the empty leading space a chip fills out to
            // (every chip is stretched to the grid column's full width) did
            // nothing. The visible chip and the tappable chip are now the
            // same rectangle.
            Button(action: onTap) {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: isActive ? "checkmark" : symbolName)
                        .font(Theme.Typography.iconRow)
                    Text(label)
                        .font(Theme.Typography.body)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isActive, let onConfigure {
                Button(action: onConfigure) {
                    Image(systemName: "gearshape.fill")
                        .font(Theme.Typography.iconRow)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        // A larger tap target than a chip strictly needs to be — these are
        // pressed mid-combat, when a bigger target beats a denser grid.
        .foregroundColor(isActive ? tint : Theme.textSecondary)
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isActive ? tint.opacity(0.20) : Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .stroke(isActive ? tint.opacity(0.55) : Theme.border.opacity(0.5), lineWidth: Theme.hairline)
        )
    }
}

/// Like `EffectChip`, but for a countable resource instead of an on/off: the
/// label carries a remaining/total readout, and the cog is always present
/// (never conditional on being "active") since a limited use always has
/// something worth configuring — its name or its count.
struct LimitedUseChip: View {
    let use: LimitedUse
    let onUse: () -> Void
    let onConfigure: () -> Void

    private var isExhausted: Bool { use.remaining == 0 }

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Same fix as `EffectChip`: `.frame(maxWidth: .infinity)` +
            // `.contentShape(Rectangle())` inside the button's own label so
            // the tappable area fills the chip instead of hugging the text —
            // this also replaces the old `Spacer(minLength: 0)` between the
            // two buttons, since the expanding button now does that job.
            Button(action: onUse) {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "star.circle.fill")
                        .font(Theme.Typography.iconRow)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(use.name)
                            .font(Theme.Typography.body)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        Text("\(use.remaining)/\(use.total)")
                            .font(Theme.Typography.caption)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isExhausted)

            Button(action: onConfigure) {
                Image(systemName: "gearshape.fill")
                    .font(Theme.Typography.iconRow)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .foregroundColor(isExhausted ? Theme.textTertiary : Theme.statusWarn)
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isExhausted ? Theme.surface : Theme.statusWarn.opacity(0.20))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .stroke(isExhausted ? Theme.border.opacity(0.5) : Theme.statusWarn.opacity(0.55), lineWidth: Theme.hairline)
        )
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
