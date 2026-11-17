import SwiftUI

struct ContentView: View {
    let session: CombatSession
    let sessionStore: SessionStore
    let presetStore: PresetStore
    @Binding var path: NavigationPath
    /// Back goes to the screen before instead of the main menu. Only Test
    /// Scenarios sets it, so a tester can try one scenario after another.
    var backReturnsToPreviousScreen = false

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
    /// A concentration check raised by damage taken as the turn began (Burning).
    /// Held until the prompt sheet has finished dismissing, then asked on its own: it
    /// resolves directly, since the turn has already moved.
    @State private var raisedChecks: [TurnPrompt] = []
    @State private var concentrationCheck: TurnPrompt?

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
                ForEach(session.combatants) { combatant in
                    let isCurrent = session.highlightedCombatantID(awaiting: pendingPrompts) == combatant.id
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
                    // Swipe left kills a living combatant, and removes a dead one.
                    // Swipe right on a dead combatant revives it. Each is undoable with Previous.
                    .swipeActions(edge: .trailing) {
                        if combatant.isDead {
                            Button(role: .destructive) {
                                session.removeCombatant(id: combatant.id)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        } else {
                            Button {
                                session.kill(combatant.id)
                            } label: {
                                Label("Kill", systemImage: "xmark.circle")
                            }
                            .tint(Theme.statusBad)
                        }
                    }
                    .swipeActions(edge: .leading) {
                        if combatant.isDead {
                            Button {
                                session.revive(combatant.id)
                            } label: {
                                Label("Revive", systemImage: "heart.fill")
                            }
                            .tint(Theme.statusGood)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .sharedStatColumns()
            // `.safeAreaInset` rather than a plain VStack sibling: the roster
            // still reserves room for the bar at rest, but rows now scroll
            // *behind* it instead of stopping dead above a hard-edged bar —
            // same floating-over-content treatment as the search field on
            // the Creatures/Encounters lists.
            .safeAreaInset(edge: .bottom) {
                TurnControlBar(
                    canGoBack: session.canGoToPreviousTurn,
                    canAdvance: !session.combatants.isEmpty,
                    onPrevious: { session.previousTurn() },
                    onNext: { advanceTurn() }
                )
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.sm)
            }
        }
        // Renaming the session: a tap anywhere else puts the keyboard away.
        .dismissesKeyboardOnTap()
        .themedScreen()
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // Two icons on each side, so both sides are the same width and the
            // title sits on the screen's centre line without being measured.
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button(action: backToMenu) {
                    Image(systemName: "chevron.left")
                }
                .accessibilityLabel(backReturnsToPreviousScreen ? "Back" : "Back to Menu")

                Button { showLog = true } label: {
                    Image(systemName: "list.bullet.rectangle")
                }
                .accessibilityLabel("Log")
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
                        .sectionLabel(color: Theme.accent)
                        .allowsHitTesting(false)
                }
                // Fills the space between the buttons; with two icons on each
                // side that space is centred on the screen.
                .frame(maxWidth: .infinity)
            }

            // "+" adds a combatant, exactly as it does on Creatures and
            // Encounters, in the same corner as on every other screen.
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button { session.playerViewEnabled.toggle() } label: {
                    Image(systemName: session.playerViewEnabled ? "eye.slash.fill" : "eye.fill")
                }
                .accessibilityLabel(session.playerViewEnabled ? "Show DM View" : "Show Player View")

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
        ), onDismiss: {
            concentrationCheck = raisedChecks.first
            raisedChecks = []
        }) {
            TurnPromptView(prompts: pendingPrompts) { answers, damage in
                raisedChecks = session.nextTurn(resolving: answers, damage: damage)
                pendingPrompts = []
            }
        }
        .concentrationCheckSheet($concentrationCheck, session: session)
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
        path.removeLast(backReturnsToPreviousScreen ? 1 : path.count)
    }

    private func autosave() {
        guard !session.combatants.isEmpty else { return }
        sessionStore.save(session.makeRecord())
        sessionStore.setLastActiveSessionID(session.id)
    }
}

/// Previous and Next, pinned below the initiative list at the ends where the
/// thumbs are. Written once with the iOS 26 glass applied conditionally.
/// Previous is the undo arrow, since it reverts to before the last Next; Next is
/// a plain arrow on to the next combatant, filled with the accent as the screen's
/// main action. The log and player view are in the toolbar, one each side.
/// Tried before this: a ⋯ menu (in the toolbar, then in this bar), a small sheet,
/// the log behind the round counter, and the four buttons down here in pairs.
private struct TurnControlBar: View {
    let canGoBack: Bool
    let canAdvance: Bool
    let onPrevious: () -> Void
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
            barButton("arrow.uturn.backward", label: "Previous Turn",
                      tint: canGoBack ? Theme.accent : Theme.textTertiary, glass: glass, action: onPrevious)
                .disabled(!canGoBack)
            Spacer()
            barButton("arrow.right", label: "Next Turn", tint: Theme.accent, glass: glass, prominent: true, action: onNext)
                .disabled(!canAdvance)
        }
    }

    /// One circular symbol button: glass from iOS 26, a plain bordered circle
    /// before it. The frame and `.contentShape` make the whole circle tappable,
    /// not only the symbol's own pixels.
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

    /// Player view exists for turning the screen around, and the party do not
    /// necessarily share their hit points with each other, so it hides everyone's
    /// numbers, party included. The table can share them if it wants to.
    @ViewBuilder
    private var healthRow: some View {
        StatReadout(systemImage: "heart.fill", iconColor: Theme.statusBad, column: .hp) {
            // Current HP is the total in play, temporary HP included, as AC is;
            // the band in player view still reads real HP against max.
            if let current = combatant.effectiveCurrentHP, let real = combatant.currentHP, let max = combatant.maxHP {
                if playerViewEnabled {
                    let band = StatusBand.health(current: real, max: max)
                    Text(band.label).foregroundColor(band.color)
                } else {
                    currentText(current) + slash + maxText(max)
                }
            } else {
                // No HP tracked: the heart stays, with a dash for each number.
                Text("−/−").foregroundColor(Theme.textTertiary)
            }
        }
    }

    /// Current HP is marked as raised for as long as temporary HP is on top of it.
    private func currentText(_ current: Int) -> Text {
        marked(current, change: combatant.temporaryHP != nil ? 1 : nil)
    }
    private func maxText(_ max: Int) -> Text { marked(max, change: combatant.recentMaxHPChange) }
    private var slash: Text { Text("/").fontWeight(.regular).foregroundColor(Theme.textTertiary) }

    /// A number that is raised or lowered: bold, red when down, green when up. No
    /// amount on the roster: the detail screen shows how much.
    private func marked(_ value: Int, change: Int?, raisedColor: Color = Theme.statusGood) -> Text {
        if let change {
            let color = change < 0 ? Theme.statusBad : raisedColor
            return Text("\(value)").fontWeight(.bold).foregroundColor(color)
        }
        // Regular, not the readout's semibold, so a bold buff stands out from it.
        return Text("\(value)").fontWeight(.regular).foregroundColor(Theme.textSecondary)
    }

    @ViewBuilder
    private var armorClassRow: some View {
        // The armor class in play, temporary AC included.
        if let ac = combatant.effectiveArmorClass {
            StatReadout(systemImage: "shield.fill", iconColor: Theme.statusInfo, column: .ac) {
                // In player view HP and AC are bands for every combatant.
                if playerViewEnabled {
                    Text(StatusBand.armorClass(ac)).foregroundColor(Theme.textSecondary)
                } else {
                    // Marked for as long as temporary AC lasts, as current HP is
                    // for temporary HP; otherwise for a change since the turn began.
                    // Raised AC is blue, the shield's colour, rather than green.
                    marked(ac, change: combatant.temporaryAC != nil ? 1 : combatant.recentACChange, raisedColor: Theme.statusInfo)
                }
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Five sections, each with its own column, so the same section lines up
            // down the list: initiative, name, death-save tally, HP, AC. The tally's
            // column is reserved even when the combatant is not dying.
            HStack(spacing: Theme.Spacing.sm) {
                Text("\(combatant.initiative)")
                    .font(Theme.Typography.numeric(21))
                    .foregroundColor(isCurrent ? Theme.accent : Theme.textSecondary)
                    .statColumn(.initiative)

                HStack(spacing: Theme.Spacing.xs) {
                    // Who is who at a glance: a person for the party, a paw for
                    // what they are fighting. Quiet, and named for VoiceOver.
                    Image(systemName: combatant.isPlayer ? "person.fill" : "pawprint.fill")
                        .font(Theme.Typography.iconInline)
                        .foregroundColor(Theme.textTertiary)
                        .accessibilityLabel(combatant.isPlayer ? "Character" : "Creature")
                    Text(combatant.name)
                        .lineLimit(1)
                        .font(Theme.Typography.rowTitle)
                        .foregroundColor(Theme.textPrimary)
                        .strikethrough(combatant.isDead)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // While dying, the tally takes the HP column's place.
                Group {
                    if combatant.isDying, let saves = combatant.deathSaves {
                        // "skull.fill" is not an SF Symbol, so the dying mark is the
                        // broken heart, above the tally like every other readout.
                        StatReadout(systemImage: "heart.slash.fill", iconColor: Theme.statusBad, column: .hp) {
                            DeathSaveDots(saves: saves)
                        }
                    } else {
                        healthRow
                    }
                }

                armorClassRow
            }

            // Glance-at-a-glance list, not the detail screen — a short label
            // (e.g. "Stunned") alongside the icon in each chip, not bare
            // symbols alone. Concentration shows here too, first, since damage
            // can break it; Reaction lives only on the detail screen.
            // FlowLayout wraps to the next line on overflow.
            if !combatant.visibleEffects.isEmpty || combatant.isStabilised || combatant.isConcentrating {
                FlowLayout {
                    if combatant.isConcentrating {
                        StatusChip(symbolName: "wand.and.rays", label: "Concentrating", color: Theme.statusInfo)
                    }
                    // The Dying effect shows as a plain "Dying" chip; its tally is beside the name.
                    ForEach(combatant.visibleEffects) { effect in
                        StatusChip(symbolName: effect.symbolName, label: effect.name, color: effect.tint)
                    }
                    // Stabilised is a status, not a mark: at 0 HP, not rolling, not
                    // waking up. Yellow, the warning colour, so it reads as "still
                    // down" without the alarm of the red Dying chip.
                    if combatant.isStabilised {
                        StatusChip(symbolName: "bandage.fill", label: "Stabilised", color: Theme.statusWarn)
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
                            Text(effect.durationType.roundDescription)
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
        .padding(.vertical, Theme.Spacing.xsm)
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
