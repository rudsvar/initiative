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
    /// "Is Alpha concentrating on Frightened?", asked after a condition goes on
    /// this combatant during someone else's turn.
    @State private var concentrationSuggestion: ConcentrationSuggestion?
    /// Held while the custom-effect sheet closes, then asked.
    @State private var queuedSuggestion: ConcentrationSuggestion?
    /// Which limited-use resource the cog opened, or nil when adding a new one.
    @State private var editingLimitedUse: LimitedUse?
    @State private var creatingLimitedUse = false
    /// The initiative being typed. Applied when the field loses focus or the
    /// screen closes, not per keystroke: each change re-sorts the order and is
    /// logged, so typing "25" must not also log a 2.
    @State private var initiativeText = ""
    @FocusState private var initiativeFocused: Bool

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
            set: { session.renameCombatant(combatantId, to: $0) }
        )
    }

    private func applyInitiative() {
        if let value = Int(initiativeText) {
            session.setInitiative(value, for: combatantId)
        }
        initiativeText = combatant.map { String($0.initiative) } ?? ""
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
                // The Health and Armor Class rows' labels share one column.
                .sharedLabelColumn()
                .padding(Theme.Spacing.lg)
            }
        }
        // Renaming, or typing an initiative: a tap anywhere else puts the keyboard away.
        .dismissesKeyboardOnTap()
        .themedScreen()
        .onAppear { initiativeText = combatant.map { String($0.initiative) } ?? "" }
        .onChange(of: initiativeFocused) { _, focused in
            if !focused { applyInitiative() }
        }
        .onDisappear { applyInitiative() }
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
        .concentrationCheckSheet($concentrationCheck, session: session)
        .alert(
            concentrationSuggestion?.question ?? "",
            isPresented: Binding(get: { concentrationSuggestion != nil }, set: { if !$0 { concentrationSuggestion = nil } }),
            presenting: concentrationSuggestion
        ) { suggestion in
            Button("Concentrating") { session.accept(suggestion) }
            Button("No", role: .cancel) {}
        } message: { suggestion in
            Text("It was put on during \(suggestion.casterName)'s turn.")
        }
        .sheet(item: $editingEffect) { effect in
            EffectEditorView(session: session, combatantID: combatantId, existing: effect)
        }
        .sheet(isPresented: $creatingCustom, onDismiss: {
            concentrationSuggestion = queuedSuggestion
            queuedSuggestion = nil
        }) {
            EffectEditorView(session: session, combatantID: combatantId, existing: nil) { effect in
                queuedSuggestion = session.concentrationSuggestion(forAdding: effect, to: combatantId)
            }
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
            if let block = SRDCatalog.block(forCombatantNamed: combatant.name) {
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
                TextField(text: $initiativeText) {
                    Text("—").foregroundColor(Theme.placeholderText)
                }
                .focused($initiativeFocused)
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

            // Kill and revive live here and in the roster's swipes, both undoable with Previous.
            Button(combatant.isDead ? "Revive" : "Kill") {
                if combatant.isDead {
                    session.revive(combatantId)
                } else {
                    session.kill(combatantId)
                }
            }
            .font(Theme.Typography.bodyEmphasis)
            .foregroundColor(combatant.isDead ? Theme.statusGood : Theme.statusBad)
            .buttonStyle(.plain)
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
                    onTap: { session.toggleReaction(for: combatant.id) },
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
                                let effect = Effect(name: condition.name, durationType: condition.defaultDuration)
                                session.addEffect(effect, to: combatant.id)
                                concentrationSuggestion = session.concentrationSuggestion(forAdding: effect, to: combatant.id)
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
                        symbolName: Effect.cooldownSymbol(for: cooldown.durationType),
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
            let otherEffects = combatant.customEffects
            let dying = combatant.isDying ? combatant.effects.first { $0.deathSaves != nil } : nil
            if !otherEffects.isEmpty || dying != nil {
                VStack(spacing: Theme.Spacing.sm) {
                    // Shown, never removed or edited here: healing, Kill, or the
                    // death saves themselves end it.
                    if let dying {
                        EffectRowView(effect: dying, onRemove: nil)
                    }
                    ForEach(otherEffects) { effect in
                        // `onTapGesture` rather than wrapping in a `Button`: the
                        // row already contains its own Remove button, and a
                        // button nested in a button loses its own tap target.
                        EffectRowView(effect: effect, onRemove: { session.removeEffect(effect.id, from: combatant.id) })
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

}

struct DeadBadge: View {
    var body: some View {
        HStack(spacing: Theme.Spacing.xsm) {
            Image(systemName: "skull.fill")
            Text("Dead")
                .sectionLabel(color: Theme.textPrimary)
        }
        .font(Theme.Typography.iconInline)
        .foregroundColor(Theme.textPrimary)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xsm)
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
        .toggleChip(tint: tint, isActive: isActive, inactiveForeground: Theme.textSecondary)
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
        .toggleChip(tint: Theme.statusWarn, isActive: !isExhausted, inactiveForeground: Theme.textTertiary)
    }
}

struct EffectRowView: View {
    let effect: Effect
    /// Nil for a row that can't be removed by hand (Dying).
    let onRemove: (() -> Void)?

    private var subtitle: String {
        guard let saves = effect.deathSaves else { return effect.durationType.description }
        return "\(saves.successes) made · \(saves.failures) failed"
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: effect.symbolName)
                .font(Theme.Typography.iconRow)
                .foregroundColor(effect.tint)
                .frame(width: 30, height: 30)
                .background(effect.tint.opacity(0.14))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(effect.name)
                    .font(Theme.Typography.bodyEmphasis)
                    .foregroundColor(Theme.textPrimary)

                Text(subtitle)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.textTertiary)
            }

            Spacer()

            if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(Theme.Typography.iconControl)
                        .foregroundColor(Theme.textTertiary)
                        .padding(Theme.Spacing.sm)
                }
                .accessibilityLabel("Remove \(effect.name)")
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Theme.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
    }
}

private extension View {
    /// The look shared by the combatant screen's chips: filled with `tint` while
    /// active, plain surface otherwise. A larger tap target than a chip strictly
    /// needs — these are pressed mid-combat, when a bigger target beats a denser grid.
    func toggleChip(tint: Color, isActive: Bool, inactiveForeground: Color) -> some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
        return self
            .foregroundColor(isActive ? tint : inactiveForeground)
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isActive ? tint.opacity(0.20) : Theme.surface)
            .clipShape(shape)
            .overlay(shape.stroke(isActive ? tint.opacity(0.55) : Theme.border.opacity(0.5), lineWidth: Theme.hairline))
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
