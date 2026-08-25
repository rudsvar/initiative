import SwiftUI

struct ContentView: View {
    let session: CombatSession
    let sessionStore: SessionStore
    let presetStore: PresetStore
    @Binding var path: NavigationPath

    @Environment(\.scenePhase) private var scenePhase
    @State private var showAddCombatant = false
    @State private var showLog = false
    @State private var showRoundEffects = false
    /// Non-empty while the turn is waiting on answers. Advancing is gated on it —
    /// see TurnPromptView for why the prompt can't be dismissed.
    @State private var pendingPrompts: [TurnPrompt] = []

    private var nameBinding: Binding<String> {
        Binding(get: { session.name }, set: { session.name = $0 })
    }

    var body: some View {
        VStack(spacing: 0) {
            // Above the roster rather than in it: these belong to the fight, not
            // to any row, and a pinned strip is what says so without needing a
            // label to explain it.
            if !session.roundEffects.isEmpty {
                RoundEffectStrip(effects: session.roundEffects) { showRoundEffects = true }
            }

            List {
                ForEach(session.sortedCombatants) { combatant in
                    CombatantRow(
                        combatant: combatant,
                        isCurrent: session.currentCombatant?.id == combatant.id,
                        playerViewEnabled: session.playerViewEnabled
                    )
                    .contentShape(Rectangle())
                    .background(
                        NavigationLink(destination: CombatantDetailView(session: session, combatantId: combatant.id)) {
                            EmptyView()
                        }
                        .opacity(0)
                    )
                    .cardRowLayout()
                    .swipeActions(edge: .trailing) {
                        // No confirmation dialog: swipe-to-reveal plus a tap on
                        // Delete is already two deliberate actions, and it's the
                        // pattern every other list in the app uses.
                        Button(role: .destructive) {
                            session.removeCombatant(id: combatant.id)
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)

            TurnControlBar(
                canGoBack: session.canGoToPreviousTurn,
                canAdvance: !session.sortedCombatants.isEmpty,
                playerViewEnabled: session.playerViewEnabled,
                onPrevious: { session.previousTurn() },
                onTogglePlayerView: { session.playerViewEnabled.toggle() },
                onShowLog: { showLog = true },
                onShowRoundEffects: { showRoundEffects = true },
                onNext: { advanceTurn() }
            )
        }
        .themedScreen()
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // Icon-only (no "Menu" text): keeps this item the same width as the
            // trailing hamburger button below, which is what lets .principal
            // center the session name/round on the true screen center.
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: backToMenu) {
                    Image(systemName: "chevron.left")
                }
                .accessibilityLabel("Back to Menu")
            }

            ToolbarItem(placement: .principal) {
                VStack(spacing: Theme.Spacing.xxs) {
                    SelectAllTextField(
                        text: nameBinding,
                        placeholder: "Session Name",
                        font: .preferredFont(forTextStyle: .headline).serif
                    )
                    .frame(height: 20)
                    Text("Round \(session.roundNumber)")
                        .font(Theme.Typography.label)
                        .textCase(.uppercase)
                        .tracking(0.9)
                        .foregroundColor(Theme.accent)
                        .allowsHitTesting(false)
                }
                .frame(width: 200)
            }

            // "+" adds a combatant, exactly as it does on Creatures and
            // Encounters. The options menu it replaced moved to the bottom bar,
            // where the turn controls already are — the two things you reach for
            // mid-combat now sit in the same place, and the one thing that's the
            // same on every screen is in the same corner on every screen.
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddCombatant = true }) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Combatant")
            }
        }
        .onDisappear { autosave() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                autosave()
            }
        }
        .sheet(isPresented: $showAddCombatant) {
            AddCombatantSheet(session: session, presetStore: presetStore, isPresented: $showAddCombatant)
        }
        .sheet(isPresented: $showLog) {
            LogView(session: session)
        }
        .sheet(isPresented: $showRoundEffects) {
            RoundEffectsView(session: session, isPresented: $showRoundEffects)
        }
        .sheet(isPresented: Binding(
            get: { !pendingPrompts.isEmpty },
            set: { if !$0 { pendingPrompts = [] } }
        )) {
            TurnPromptView(prompts: pendingPrompts) { answers in
                pendingPrompts = []
                session.nextTurn(resolving: answers)
            }
        }
    }

    /// Rolls owed at this boundary are asked before the turn moves, and the
    /// answers are handed to `nextTurn` rather than applied separately — that puts
    /// them inside the same undo step as the advance itself.
    private func advanceTurn() {
        let prompts = session.pendingTurnPrompts()
        if prompts.isEmpty {
            session.nextTurn()
        } else {
            pendingPrompts = prompts
        }
    }

    private func backToMenu() {
        autosave()
        path.removeLast(path.count)
    }

    private func autosave() {
        guard !session.combatants.isEmpty else { return }
        sessionStore.save(session.makeRecord())
        sessionStore.setLastActiveSessionID(session.id)
    }
}

/// Previous / options / Next, pinned below the initiative list. Written once with
/// the iOS 26 glass treatment applied conditionally, rather than as two
/// near-identical copies of the whole bar — the layout is the same either way,
/// only the button material differs.
///
/// The centre slot holds the session's own controls (player view, log) rather
/// than Add: adding a combatant is the same action it is on every other screen
/// and belongs in the same top-right corner, while these two exist only here.
private struct TurnControlBar: View {
    let canGoBack: Bool
    let canAdvance: Bool
    let playerViewEnabled: Bool
    let onPrevious: () -> Void
    let onTogglePlayerView: () -> Void
    let onShowLog: () -> Void
    let onShowRoundEffects: () -> Void
    let onNext: () -> Void

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: Theme.Spacing.md) {
                content(glass: true)
            }
        } else {
            content(glass: false)
                .background(Theme.background)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Theme.border.opacity(0.5))
                        .frame(height: Theme.hairline)
                }
        }
    }

    private func content(glass: Bool) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            stepButton(
                label: "Previous",
                systemImage: "chevron.left",
                iconLeading: true,
                prominent: false,
                glass: glass
            ) { onPrevious() }
            .disabled(!canGoBack)
            .frame(maxWidth: .infinity, alignment: .leading)

            optionsButton(glass: glass)
                .frame(maxWidth: .infinity, alignment: .center)

            stepButton(
                label: "Next",
                systemImage: "chevron.right",
                iconLeading: false,
                prominent: true,
                glass: glass
            ) { onNext() }
            .disabled(!canAdvance)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(Theme.Spacing.lg)
    }

    @ViewBuilder
    private func stepButton(
        label: String,
        systemImage: String,
        iconLeading: Bool,
        prominent: Bool,
        glass: Bool,
        action: @escaping () -> Void
    ) -> some View {
        let content = Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                if iconLeading { Image(systemName: systemImage) }
                Text(label)
                if !iconLeading { Image(systemName: systemImage) }
            }
            .font(Theme.Typography.bodyEmphasis)
        }

        if glass, #available(iOS 26.0, *) {
            if prominent {
                content.buttonStyle(.glassProminent).tint(Theme.accent)
            } else {
                content.buttonStyle(.glass)
            }
        } else {
            content.foregroundColor(prominent ? Theme.accent : Theme.textSecondary)
        }
    }

    @ViewBuilder
    private func optionsButton(glass: Bool) -> some View {
        let content = Menu {
            Button(action: onTogglePlayerView) {
                Label(
                    playerViewEnabled ? "Show DM View" : "Show Player View",
                    systemImage: playerViewEnabled ? "eye.slash.fill" : "eye.fill"
                )
            }
            Button(action: onShowLog) {
                Label("Log", systemImage: "list.bullet.clipboard")
            }
        } label: {
            Image(systemName: "line.3.horizontal")
                .font(Theme.Typography.iconPrimaryAction)
        }
        .accessibilityLabel("Session Options")

        if glass, #available(iOS 26.0, *) {
            content.buttonStyle(.glass)
        } else {
            content.foregroundColor(Theme.accent)
        }
    }
}

struct CombatantRow: View {
    let combatant: Combatant
    let isCurrent: Bool
    let playerViewEnabled: Bool

    // Computed synchronously (not via GeometryReader + @State) so FlowLayout gets
    // a correct width on the very first layout pass. List rows are self-sizing
    // once, on first appearance — if the true width only became known a frame
    // later (as with a GeometryReader background), List had already committed a
    // too-short row height and never re-measured, clipping wrapped chip rows.
    // Screen width minus the row's own fixed insets is deterministic up front.
    private var rowWidth: CGFloat {
        // 2 * Spacing.sm listRowInsets + 2 * Spacing.md cardRowStyle padding.
        UIScreen.main.bounds.width - (2 * Theme.Spacing.sm + 2 * Theme.Spacing.md)
    }

    private func chipSymbol(for effect: Effect, condition: StandardCondition?) -> String {
        switch effect.kind {
        case .cooldown: return effect.durationType.awaitsRoll ? "hourglass" : "clock"
        case .concentration: return "wand.and.rays"
        case .condition: return condition?.symbolName ?? "sparkles"
        }
    }

    private func chipTint(for effect: Effect, condition: StandardCondition?) -> Color {
        switch effect.kind {
        // A cooldown is something you can't do, not something wrong with you —
        // quiet, like the reaction chip. Concentration is a third thing again:
        // it's fine right now, but it's at risk, so it reads as information.
        case .cooldown: return Theme.textTertiary
        case .concentration: return Theme.statusInfo
        case .condition: return condition?.color ?? Theme.accent
        }
    }

    private func stateBadge(_ systemImage: String, tint: Color) -> some View {
        Image(systemName: systemImage)
            .font(Theme.Typography.iconInline)
            .foregroundColor(tint)
            .padding(Theme.Spacing.xs)
            .background(Theme.background.opacity(0.8))
            .clipShape(Circle())
    }

    @ViewBuilder
    private func statRow(systemImage: String, text: String, color: Color) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: systemImage)
                .font(Theme.Typography.iconInline)
                .frame(width: 12)
            Text(text)
        }
        .font(Theme.Typography.stat)
        .foregroundColor(color)
    }

    /// Player view exists for turning the screen around, and the party already
    /// know their own hit points — it's the monsters' numbers that need hiding.
    /// Blanking everyone's was the behaviour before combatants knew which they
    /// were.
    private var hideNumbers: Bool { playerViewEnabled && !combatant.isPlayer }

    @ViewBuilder
    private var healthRow: some View {
        if let current = combatant.currentHP, let max = combatant.maxHP {
            if hideNumbers {
                let band = StatusBand.health(current: current, max: max)
                statRow(systemImage: "heart.fill", text: band.label, color: band.color)
            } else {
                // The buffer is appended rather than folded into the number:
                // "26/30 +8" says both what they have and what's about to be
                // spent first, which is the thing you're deciding against.
                let buffer = combatant.temporaryHP.map { " +\($0)" } ?? ""
                statRow(systemImage: "heart.fill", text: "\(current)/\(max)\(buffer)", color: Theme.textSecondary)
            }
        }
    }

    @ViewBuilder
    private var armorClassRow: some View {
        if let ac = combatant.armorClass {
            if hideNumbers {
                let band = StatusBand.armorClass(ac)
                statRow(systemImage: "shield.fill", text: band.label, color: band.color)
            } else {
                statRow(systemImage: "shield.fill", text: "\(ac)", color: Theme.textSecondary)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.md) {
                // Big and on the far left, its own column — not a small caption
                // tucked under the name — so it reads immediately as the value the
                // list is actually sorted by. Tabular figures keep the column from
                // shifting between one- and two-digit values. Only the current
                // combatant's number is accent-colored: gold marks exactly one
                // thing on this screen, and this is the screen's one thing.
                Text("\(combatant.initiative)")
                    .font(Theme.Typography.numeric(27))
                    .foregroundColor(isCurrent ? Theme.accent : Theme.textSecondary)
                    .frame(width: 40, alignment: .center)

                HStack(spacing: Theme.Spacing.xs + 2) {
                    Text(combatant.name)
                        .font(Theme.Typography.rowTitle)
                        .foregroundColor(Theme.textPrimary)
                        .strikethrough(combatant.isDead)

                    if combatant.isDead {
                        stateBadge("skull.fill", tint: Theme.textPrimary)
                    } else if combatant.isDying {
                        // A dying combatant is the most time-critical thing on
                        // this screen, so it gets the one treatment nothing else
                        // in the row uses: a filled status colour, not a tint.
                        stateBadge("heart.slash.fill", tint: Theme.statusBad)
                    } else if combatant.isStabilised {
                        stateBadge("bandage.fill", tint: Theme.statusWarn)
                    }
                }

                Spacer(minLength: Theme.Spacing.sm)

                // Icon-led (heart/shield) instead of text labels ("14/20 HP"), and
                // left-aligned within their own column so the icons themselves
                // line up vertically regardless of how many digits each value has.
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    healthRow
                    armorClassRow
                }
            }

            // Glance-at-a-glance list, not the detail screen — a short label (e.g.
            // "Stunned") alongside the icon in each chip, not bare symbols alone.
            // Reaction-used is just another status chip among the rest. FlowLayout
            // wraps to the next line on overflow instead of clipping.
            if combatant.reactionUsed || !combatant.visibleEffects.isEmpty {
                FlowLayout {
                    if combatant.reactionUsed {
                        StatusChip(symbolName: "arrow.uturn.left", label: "Reaction", color: Theme.textTertiary)
                    }
                    ForEach(combatant.visibleEffects) { effect in
                        let condition = ConditionLibrary.matching(name: effect.name)
                        StatusChip(
                            symbolName: chipSymbol(for: effect, condition: condition),
                            label: effect.name,
                            // A cooldown is something you can't do, not something
                            // wrong with you — quiet, like the reaction chip.
                            color: chipTint(for: effect, condition: condition)
                        )
                    }
                }
                .frame(width: rowWidth, alignment: .leading)
            }
        }
        .cardRowStyle(isHighlighted: isCurrent)
        // Dying combatants stay at full strength: they're the ones that need
        // attention, and fading them would say the opposite.
        .opacity(combatant.isDead ? 0.5 : 1)
    }
}

/// What's happening to the whole fight, pinned above the roster. Tapping it
/// opens the manage screen — the strip is a readout, and everything it shows is
/// already one tap from being changed.
private struct RoundEffectStrip: View {
    let effects: [Effect]
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "theatermasks")
                    .font(Theme.Typography.iconRow)
                    .foregroundColor(Theme.statusInfo)

                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    ForEach(effects) { effect in
                        HStack(spacing: Theme.Spacing.xs) {
                            Text(effect.name)
                                .font(Theme.Typography.bodyEmphasis)
                                .foregroundColor(Theme.textPrimary)
                            Text(effect.durationType.description)
                                .font(Theme.Typography.caption)
                                .foregroundColor(Theme.textTertiary)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Theme.border.opacity(0.5))
                    .frame(height: Theme.hairline)
            }
        }
        .buttonStyle(.plain)
    }
}

/// A single status in its own small chip — used for both reaction-used and effect
/// conditions in the combatant list, laid out via FlowLayout so several can sit
/// side by side and wrap instead of clipping. The chip takes its own color from
/// the condition's category (see `ConditionCategory`) at low opacity, so a row of
/// chips is legible as a group without any one of them competing with the accent.
private struct StatusChip: View {
    let symbolName: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: symbolName)
                .font(Theme.Typography.iconChip)
            Text(label)
                .font(Theme.Typography.label)
        }
        .foregroundColor(color)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs + 2)
        .background(color.opacity(0.13))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .stroke(color.opacity(0.28), lineWidth: Theme.hairline)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        ContentView(session: CombatSession(), sessionStore: SessionStore(), presetStore: PresetStore(), path: .constant(NavigationPath()))
    }
}
