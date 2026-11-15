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
    /// Non-empty while the turn is waiting on answers. Dismissing the prompt
    /// sheet (it's freely swipeable — see `TurnPromptView`) just clears this
    /// back to empty without advancing; `session.nextTurn` only ever runs
    /// from the sheet's own completion callback, once every prompt has an
    /// answer.
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
                    let isCurrent = session.currentCombatant?.id == combatant.id
                    // A real Button, not a hidden NavigationLink in the
                    // background: the hidden-link pattern gave the row zero
                    // visible feedback on tap, since its own press-dimming
                    // applied to an invisible EmptyView rather than the
                    // actually-displayed CombatantRow content.
                    Button(action: { path.append(Route.combatantDetail(combatant.id)) }) {
                        CombatantRow(
                            combatant: combatant,
                            isCurrent: isCurrent,
                            playerViewEnabled: session.playerViewEnabled
                        )
                    }
                    .buttonStyle(CardRowButtonStyle(isHighlighted: isCurrent))
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
            // `.safeAreaInset` rather than a plain VStack sibling: the roster
            // still reserves room for the bar at rest, but rows now scroll
            // *behind* it instead of stopping dead above a hard-edged bar —
            // same floating-over-content treatment as the search field on
            // the Creatures/Encounters lists.
            .safeAreaInset(edge: .bottom) {
                TurnControlBar(
                    canGoBack: session.canGoToPreviousTurn,
                    canAdvance: !session.sortedCombatants.isEmpty,
                    playerViewEnabled: session.playerViewEnabled,
                    onPrevious: { session.previousTurn() },
                    onTogglePlayerView: { session.playerViewEnabled.toggle() },
                    onShowLog: { showLog = true },
                    onNext: { advanceTurn() }
                )
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.sm)
            }
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
/// Four separate buttons, not one fused bar (tried and it read as a single
/// odd blob rather than distinct controls) — Log paired next to Previous,
/// View paired next to Next, evenly spaced across the width. Media-style
/// icons (`backward.fill`/`forward.fill`, not chevrons) since stepping
/// through turns is the same shape as transport controls. View and Log used
/// to live behind a hamburger `Menu` — direct, always-visible buttons are one
/// tap instead of two for the pair of things reached for almost as often as
/// Next itself.
private struct TurnControlBar: View {
    let canGoBack: Bool
    let canAdvance: Bool
    let playerViewEnabled: Bool
    let onPrevious: () -> Void
    let onTogglePlayerView: () -> Void
    let onShowLog: () -> Void
    let onNext: () -> Void

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: Theme.Spacing.md) {
                content(glass: true)
            }
        } else {
            content(glass: false)
        }
    }

    private func content(glass: Bool) -> some View {
        HStack(spacing: 0) {
            // Arrows on the ends, View/Log in the middle two slots — Log
            // still sits next to Previous and View next to Next.
            barButton(
                "backward.fill",
                label: "Previous Turn",
                tint: canGoBack ? Theme.accent : Theme.textTertiary,
                glass: glass,
                action: onPrevious
            )
            .disabled(!canGoBack)
            .frame(maxWidth: .infinity)

            barButton("list.bullet.clipboard", label: "Log", tint: Theme.textSecondary, glass: glass, action: onShowLog)
                .frame(maxWidth: .infinity)

            barButton(
                playerViewEnabled ? "eye.slash.fill" : "eye.fill",
                label: playerViewEnabled ? "Show DM View" : "Show Player View",
                tint: Theme.textSecondary,
                glass: glass,
                action: onTogglePlayerView
            )
            .frame(maxWidth: .infinity)

            barButton("forward.fill", label: "Next Turn", tint: Theme.accent, glass: glass, prominent: true, action: onNext)
                .disabled(!canAdvance)
                .frame(maxWidth: .infinity)
        }
    }

    /// `.frame(maxWidth: .infinity)` on the label (not chained onto the
    /// `Button` from outside) plus `.contentShape(Rectangle())` — a plain
    /// `Button`'s tap target is only ever as big as its label's own rendered
    /// content, so a `.frame()` applied afterward stretches the layout slot
    /// without stretching what's actually tappable inside it.
    @ViewBuilder
    private func barButton(
        _ systemImage: String,
        label: String,
        tint: Color,
        glass: Bool,
        prominent: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        let button = Button(action: action) {
            Image(systemName: systemImage)
                .font(Theme.Typography.iconPrimaryAction)
                .frame(width: 52, height: 52)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(label)

        if glass, #available(iOS 26.0, *) {
            if prominent {
                button.buttonStyle(.glassProminent).tint(Theme.accent)
            } else {
                button.buttonStyle(.glass).tint(tint)
            }
        } else {
            button
                .buttonStyle(.plain)
                .foregroundColor(tint)
                .background(Theme.background)
                .clipShape(Circle())
                .overlay(Circle().stroke(Theme.border.opacity(0.5), lineWidth: Theme.hairline))
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
        case .condition: return condition?.symbolName ?? "sparkles"
        }
    }

    private func chipTint(for effect: Effect, condition: StandardCondition?) -> Color {
        switch effect.kind {
        // A cooldown is something you can't do, not something wrong with you —
        // quiet, like the reaction chip.
        case .cooldown: return Theme.textTertiary
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
    private func statRow(systemImage: String, iconColor: Color, text: String, textColor: Color) -> some View {
        statRow(systemImage: systemImage, iconColor: iconColor, content: Text(text), textColor: textColor)
    }

    /// Icon trails the text rather than leading it, both pinned to a fixed
    /// width — that's what makes the heart on one row and the shield on the
    /// next line up at the same right edge regardless of how many digits the
    /// text before them has. Icon color is fixed per stat (heart red, shield
    /// blue) independent of the text color, which still carries the
    /// health/AC-band color in player view.
    @ViewBuilder
    private func statRow(systemImage: String, iconColor: Color, content: Text, textColor: Color) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            content
                .foregroundColor(textColor)
            Image(systemName: systemImage)
                .font(Theme.Typography.iconInline)
                .foregroundColor(iconColor)
                .frame(width: 14, alignment: .center)
        }
        .font(Theme.Typography.stat)
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
                statRow(systemImage: "heart.fill", iconColor: Theme.statusBad, text: band.label, textColor: band.color)
            } else {
                statLine(
                    "heart.fill", Theme.statusBad,
                    value: marked(current, change: combatant.recentHPChange)
                        + Text("/").foregroundColor(Theme.textTertiary)
                        + marked(max, change: combatant.recentMaxHPChange),
                    temp: combatant.temporaryHP
                )
            }
        }
    }

    /// A number that changed since its turn started: bold, red when down, green when
    /// up. No arrow and no amount: the detail screen shows the amount. An unchanged
    /// number is plain.
    private func marked(_ value: Int, change: Int?) -> Text {
        guard let change else {
            return Text("\(value)").foregroundColor(Theme.textSecondary)
        }
        let color = change < 0 ? Theme.statusBad : Theme.statusGood
        return Text("\(value)").fontWeight(.bold).foregroundColor(color)
    }

    /// One stat line in fixed columns, so every roster row lines up: temp text, then
    /// the value flush right, then its icon trailing it, as on the rest of the app.
    private func statLine(_ systemImage: String, _ iconColor: Color, value: Text, temp: Int?) -> some View {
        HStack(spacing: 0) {
            // The icon comes first, as large as the initiative number beside it.
            Image(systemName: systemImage)
                .font(Theme.Typography.numeric(18))
                .foregroundColor(iconColor)
                .frame(width: 20, alignment: .center)
            // Temporary value: shield and number, then the value and its arrow.
            // Only takes room when there is a temporary value.
            if let temp {
                Text("\(Image(systemName: "shield.fill")) \(temp)")
                    .foregroundColor(Theme.statusInfo)
                    .padding(.leading, Theme.Spacing.xxs)
            }
            value
                .padding(.leading, Theme.Spacing.xs)
        }
        .font(Theme.Typography.rowStat)
    }

    @ViewBuilder
    private var armorClassRow: some View {
        if let ac = combatant.armorClass {
            // In player view AC is a band for every combatant, so no row shows a
            // raw number that another row hides. HP keeps its own rule (hideNumbers).
            if playerViewEnabled {
                let band = StatusBand.armorClass(ac)
                statRow(systemImage: "shield.fill", iconColor: Theme.statusInfo, text: band.label, textColor: band.color)
            } else {
                statLine(
                    "shield.fill", Theme.statusInfo,
                    value: marked(ac, change: combatant.recentACChange),
                    temp: combatant.temporaryAC
                )
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
                    .font(Theme.Typography.numeric(21))
                    .foregroundColor(isCurrent ? Theme.accent : Theme.textSecondary)
                    .frame(width: 34, alignment: .center)

                HStack(spacing: Theme.Spacing.xs + 2) {
                    Text(combatant.name)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .layoutPriority(-1)
                        .font(Theme.Typography.rowTitle)
                        .foregroundColor(Theme.textPrimary)
                        .strikethrough(combatant.isDead)

                    // No skull for the dead: the strikethrough and the faded row already say it.
                    if combatant.isDying {
                        // A dying combatant is the most time-critical thing on
                        // this screen, so it gets the one treatment nothing else
                        // in the row uses: a filled status colour, not a tint.
                        stateBadge("heart.slash.fill", tint: Theme.statusBad)
                    } else if combatant.isStabilised {
                        stateBadge("bandage.fill", tint: Theme.statusWarn)
                    }
                }

                Spacer(minLength: Theme.Spacing.sm)

                // Icon-led (heart/shield) instead of text labels ("14/20 HP").
                // A fixed minimum width plus trailing alignment — rather than
                // leading, sized to content — is what makes the icons line up
                // vertically between rows whose names are different lengths;
                // every row's health/AC column ends at the same right edge.
                // HP and AC side by side, each with its own fixed columns.
                HStack(spacing: Theme.Spacing.lg) {
                    healthRow
                    armorClassRow
                }
                // The stats keep their natural width; the name gives way to them.
                .fixedSize()
                .layoutPriority(1)
            }

            // Glance-at-a-glance list, not the detail screen — a short label
            // (e.g. "Stunned") alongside the icon in each chip, not bare
            // symbols alone. Reaction and Concentration live only on the
            // detail screen now, not here — this strip is conditions/
            // cooldowns only. FlowLayout wraps to the next line on overflow.
            if !combatant.visibleEffects.isEmpty {
                FlowLayout {
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
        // Dying combatants stay at full strength: they're the ones that need
        // attention, and fading them would say the opposite. cardRowStyle
        // itself now lives in the enclosing Button's CardRowButtonStyle, not
        // here — this is just the row's content.
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
